#!/usr/bin/env bash
# Verify that the flake produces byte-identical build outputs.
#
#   ./scripts/verify.sh build         build current tree only (smoke test)
#   ./scripts/verify.sh               compare current tree against HEAD~1
#   ./scripts/verify.sh <ref>         compare current tree against any git ref
#   OLD=../tree ./scripts/verify.sh   compare against an existing worktree
#
# PASS means the output store paths are identical, which is a proof of
# equivalence, not an eyeball judgement. Any FAIL must be explained before
# committing.
#
# `min` is the control: it takes only the core aspect, so a change confined to
# gui must leave it identical. `default` aliases min, so comparing it costs
# nothing and asserts the alias still holds.

set -uo pipefail

TARGETS=(default min gui)
REPO=$(git rev-parse --show-toplevel) || exit 2

fail=0
pass=0

# Flakes only see tracked files. This is the single most common cause of
# spurious "path does not exist" errors.
git add -A >/dev/null 2>&1 || true

build() {
  # $1 = flake ref, $2 = attr
  nix build --no-link --print-out-paths "$1#$2" 2>/dev/null
}

if [[ ${1:-} == build ]]; then
  for t in "${TARGETS[@]}"; do
    printf '%-30s ' "$t"
    if out=$(build . "$t") && [[ -n $out ]]; then
      echo "OK"
      pass=$((pass + 1))
    else
      echo "BUILD FAILED"
      echo "  retry verbosely:  nix build .#$t"
      fail=$((fail + 1))
    fi
  done
  echo
  echo "built $pass, failed $fail"
  exit $((fail > 0))
fi

# An explicit OLD points at a tree that already exists and is not ours to
# manage. Otherwise check out the ref ourselves and clean up after.
if [[ -n ${OLD:-} ]]; then
  if [[ ! -d $OLD ]]; then
    echo "error: OLD=$OLD is not a directory"
    exit 2
  fi
  # A hand-managed tree may carry uncommitted edits; a ref worktree cannot.
  git -C "$OLD" add -A >/dev/null 2>&1 || true
  baseline=$OLD
  label_ref=$OLD
else
  ref=${1:-HEAD~1}
  if ! rev=$(git rev-parse --verify --quiet "$ref^{commit}"); then
    echo "error: '$ref' is not a commit"
    exit 2
  fi
  baseline=$(mktemp -d -t verify-baseline-XXXXXX)
  trap 'git -C "$REPO" worktree remove --force "$baseline" >/dev/null 2>&1' EXIT
  if ! git -C "$REPO" worktree add --detach "$baseline" "$rev" >/dev/null 2>&1; then
    echo "error: could not create a worktree at $ref"
    exit 2
  fi
  label_ref="$ref ($(git log -1 --format=%h "$rev"))"
fi

echo "baseline: $label_ref"
echo

command -v nvd >/dev/null || echo "note: nvd not on PATH; package diffs will not be explained"

for t in "${TARGETS[@]}"; do
  printf '%-30s ' "$t"

  old=$(build "$baseline" "$t")
  if [[ -z $old ]]; then
    echo "BASELINE BUILD FAILED"
    echo "  nix build $baseline#$t"
    fail=$((fail + 1))
    continue
  fi

  new=$(build . "$t")
  if [[ -z $new ]]; then
    echo "NEW BUILD FAILED"
    echo "  nix build .#$t"
    fail=$((fail + 1))
    continue
  fi

  if [[ $old == "$new" ]]; then
    echo "PASS"
    pass=$((pass + 1))
  else
    echo "FAIL"
    fail=$((fail + 1))
    echo "  old: $old"
    echo "  new: $new"
    diff -rq "$old" "$new" 2>&1 | sed 's/^/    /' | head -20
    if command -v nvd >/dev/null; then
      nvd diff "$old" "$new" | sed 's/^/    /'
    fi
    echo "  innocent: the generated init.lua differs only in the ORDER of"
    echo "  autocmds, augroups, keymaps or treesitter queries. Those are listOf"
    echo "  options that concatenate in module order, so any file move or merge"
    echo "  reorders them (AGENTS.md 5)."
    echo "  not innocent: a plugin appears or disappears, a version moves, a Lua"
    echo "  body differs in content, or the closure grows by ~2 GB (a formatter"
    echo "  stopped resolving from PATH)."
  fi
done

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] || echo "DO NOT COMMIT until this is 3 PASS or the difference is understood."
exit $((fail > 0))
