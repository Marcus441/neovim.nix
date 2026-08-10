#!/usr/bin/env bash
# Audit the four PATH-resolution invariants that fail silently.
#
#   ./scripts/audit-path-resolution.sh
#
# Every one of these breaks with no error anywhere -- a bundled formatter still
# builds, an unwrapped server still starts, and both are only visible in a
# closure size or a `command -v` in the wrong directory. That is what earns a
# script rather than a reading of the files.
#
#   1. min ships no language server or formatter package.
#   2. min resolves every formatter it uses from $PATH.
#   3. gui routes every server and formatter through a PATH-first wrapper.
#   4. Neither closure has quietly grown.
#
# What this CANNOT check, and a reviewer must: whether a server needs --stdio or
# other args, whether a plugin rather than nvf owns the server's activation
# (rustaceanvim does, and a duplicate client is invisible here -- count clients
# on a live buffer), and whether a wrapper is pointless for a given server.
# `.claude/skills/add-language/SKILL.md` carries that list.
#
# Rationale: docs/decisions/formatters.md, docs/decisions/prefer-path.md.

set -uo pipefail

REPO=$(git rev-parse --show-toplevel) || exit 2
SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem 2>/dev/null) || exit 2

# Deliberately bare in gui, each for a reason recorded in
# docs/decisions/formatters.md. Anything else bare there is a finding.
GUI_BARE_FORMATTERS=(rustfmt csharpier)

# Deliberately unwrapped. roslyn-ls is a dotnet assembly launched with five
# args through a raw Lua cmd; nobody has it on $PATH and a wrapper would be all
# cost, no benefit.
UNWRAPPED_SERVERS=(roslyn-ls)

# Tools this config knows how to install. min must contain none of them.
# Adding a language means adding its tool here -- the ceiling in check 4 is the
# backstop for anything this list has not caught up with.
MIN_FORBIDDEN=(
  rust-analyzer clang-tools nixd lua-language-server basedpyright
  typescript-language-server roslyn-ls omnisharp eslint_d
  csharpier prettier ruff stylua alejandra rustfmt
  dotnet-sdk dotnet-runtime nodejs lldb
)

# Tripwires, not targets. Raise deliberately, with the reason in the commit.
MIN_CEILING_MIB=350
GUI_CEILING_MIB=4096

pass=0
fail=0

ok()   { printf '  ok    %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
note() { printf '        %s\n' "$1"; }

has() { # has <needle> <haystack...>
  local n=$1; shift
  local x
  for x in "$@"; do [[ $x == "$n" ]] && return 0; done
  return 1
}

# Flakes only see tracked files (CLAUDE.md 7).
git -C "$REPO" add -A >/dev/null 2>&1 || true

# The variant records are the source of truth; this script mirrors them. Fail
# loudly rather than silently auditing a stale set.
known_variants=(gui min)
found_variants=()
for f in "$REPO"/modules/variants/*.nix; do
  b=$(basename "$f" .nix)
  [[ $b == generator ]] && continue
  found_variants+=("$b")
done
IFS=$'\n' found_variants=($(sort <<<"${found_variants[*]}")); unset IFS
if [[ "${known_variants[*]}" != "${found_variants[*]}" ]]; then
  echo "error: this script knows variants [${known_variants[*]}] but the tree has [${found_variants[*]}]"
  echo "       teach it the new one, or it audits a stale set in silence"
  exit 2
fi

echo "building both variants"
min_out=$(nix build --no-link --print-out-paths "$REPO#min" 2>/dev/null)
gui_out=$(nix build --no-link --print-out-paths "$REPO#gui" 2>/dev/null)
if [[ -z $min_out || -z $gui_out ]]; then
  echo "error: a variant failed to build; fix that before auditing it"
  exit 2
fi

expr_file=$(mktemp -t audit-XXXXXX.nix)
trap 'rm -f "$expr_file"' EXIT
sed -e "s|@ROOT@|$REPO|" -e "s|@SYSTEM@|$SYSTEM|" > "$expr_file" <<'NIX'
let
  flake = builtins.getFlake "@ROOT@";
  lib = flake.inputs.nixpkgs.lib;
  pkgs = import flake.inputs.nixpkgs {
    system = "@SYSTEM@";
    config.allowUnfreePredicate = p:
      builtins.elem (lib.getName p) ["vscode-extension-ms-dotnettools-csharp"];
  };

  conf = aspects:
    (flake.inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = map (a: flake.modules.nvf.${a}) aspects;
    })
    .config;

  describe = c: let
    setup = c.vim.formatter.conform-nvim.setupOpts;
  in {
    formatters = lib.mapAttrs (_: f: f.command or null) (setup.formatters or {});
    byFt = setup.formatters_by_ft or {};
    servers =
      lib.mapAttrs (_: s: {
        cmd =
          if builtins.isList s.cmd
          then s.cmd
          else null;
        rawCmd = s.cmd != null && !(builtins.isList s.cmd);
      })
      (lib.filterAttrs (n: _: n != "*") c.vim.lsp.servers);
  };
in {
  min = describe (conf ["core"]);
  gui = describe (conf ["core" "gui"]);
}
NIX

cfg=$(nix eval --impure --json -f "$expr_file" 2>/dev/null)
if [[ -z $cfg ]]; then
  echo "error: could not evaluate the variant configurations"
  exit 2
fi

q() { jq -r "$1" <<<"$cfg"; }

# A PATH-first wrapper is a script that consults $PATH before its fallback. The
# store path alone does not say so -- read it.
is_wrapper() {
  [[ $1 == /nix/store/* && -f $1 ]] && grep -q 'command -v' "$1"
}

echo
echo "1. min ships no language server or formatter package"
closure=$(nix path-info -r "$min_out" 2>/dev/null)
found_any=0
for tool in "${MIN_FORBIDDEN[@]}"; do
  if hits=$(grep -E "/[a-z0-9]{32}-${tool}(-[^/]*)?$" <<<"$closure"); then
    bad "min bundles $tool"
    while read -r h; do [[ -n $h ]] && note "$h"; done <<<"$hits"
    found_any=1
  fi
done
[[ $found_any -eq 0 ]] && ok "none of ${#MIN_FORBIDDEN[@]} known tools are in min's closure"

echo
echo "2. min resolves every formatter it uses from \$PATH"
mapfile -t min_used < <(q '.min.byFt | to_entries[] | .value[]' | sort -u)
if [[ ${#min_used[@]} -eq 0 ]]; then
  bad "min references no formatter at all -- format-on-save does nothing"
else
  bare_all=1
  for f in "${min_used[@]}"; do
    cmd=$(q ".min.formatters[\"$f\"] // \"\"")
    if [[ $cmd == /nix/store/* ]]; then
      bad "min pins $f"
      note "$cmd"
      bare_all=0
    elif [[ -z $cmd ]]; then
      bad "min uses $f but sets no command; nvf's pinned default wins"
      bare_all=0
    fi
  done
  [[ $bare_all -eq 1 ]] && ok "all ${#min_used[@]} formatters bare: ${min_used[*]}"
fi

echo
echo "3. gui routes every server and formatter through a PATH-first wrapper"
mapfile -t gui_servers < <(q '.gui.servers | keys[]')
for s in "${gui_servers[@]}"; do
  raw=$(q ".gui.servers[\"$s\"].rawCmd")
  if has "$s" "${UNWRAPPED_SERVERS[@]}"; then
    ok "$s exempt (documented)"
    continue
  fi
  if [[ $raw == true ]]; then
    bad "$s sets cmd as raw Lua, so it cannot be checked or wrapped"
    continue
  fi
  first=$(q ".gui.servers[\"$s\"].cmd[0] // \"\"")
  if [[ -z $first ]]; then
    bad "$s has no cmd; nvf's pinned default wins"
  elif is_wrapper "$first"; then
    ok "$s wrapped"
  else
    bad "$s is pinned, not wrapped"
    note "$first"
  fi
done

mapfile -t gui_used < <(q '.gui.byFt | to_entries[] | .value[]' | sort -u)
for f in "${gui_used[@]}"; do
  cmd=$(q ".gui.formatters[\"$f\"] // \"\"")
  if has "$f" "${GUI_BARE_FORMATTERS[@]}"; then
    if [[ $cmd == /nix/store/* ]]; then
      bad "$f is pinned in gui, but is documented as deliberately bare"
    else
      ok "$f bare in gui (documented)"
    fi
  elif is_wrapper "$cmd"; then
    ok "$f wrapped"
  elif [[ $cmd == /nix/store/* ]]; then
    bad "$f is pinned in gui, not wrapped"
    note "$cmd"
  else
    bad "$f is bare in gui, so a launcher-started nvim has no formatter"
  fi
done

echo
echo "4. neither closure has quietly grown"
size_mib() { echo $(( $(nix path-info -S "$1" 2>/dev/null | awk '{print $2}') / 1048576 )); }
min_mib=$(size_mib "$min_out")
gui_mib=$(size_mib "$gui_out")
for pair in "min:$min_mib:$MIN_CEILING_MIB" "gui:$gui_mib:$GUI_CEILING_MIB"; do
  IFS=: read -r name got ceil <<<"$pair"
  if [[ $got -le $ceil ]]; then
    ok "$name ${got} MiB (ceiling ${ceil})"
  else
    bad "$name ${got} MiB exceeds its ${ceil} MiB ceiling"
    note "something started pinning a toolchain, or the ceiling needs raising on purpose"
  fi
done

echo
echo "$pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
  echo "Each of these fails silently at runtime. See docs/decisions/formatters.md"
  echo "and docs/decisions/prefer-path.md before changing a value to make it pass."
fi
exit $((fail > 0))
