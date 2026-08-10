#!/usr/bin/env bash
# Test what the PreToolUse hooks DO, not what their regexes look like.
#
#   ./scripts/test-hooks.sh
#
# Covers .claude/hooks/git-add-before-nix.sh. That one fails silently and in the
# expensive direction: staging during a `git commit` widens it to the whole
# working tree, nothing reports it, and the commit is wrong in a way that only
# shows up in review. `10befbb` is the fix; these are its cases.
#
# Each case drives the hook with a real tool_input payload against a throwaway
# repo and asserts on whether the index ended up dirty. Asserting on the index
# rather than on the pattern is the point — the bug `10befbb` fixed was a
# correct-looking regex whose bracket expression treated a plain space as a
# command separator, so every "matches / does not match" reading of it was wrong.

set -uo pipefail

REPO=$(git rev-parse --show-toplevel) || exit 2
HOOK="$REPO/.claude/hooks/git-add-before-nix.sh"

[[ -x $HOOK ]] || { echo "error: $HOOK is not executable"; exit 2; }
command -v jq >/dev/null || { echo "error: jq is not on PATH; the hook needs it"; exit 2; }

pass=0
fail=0

sandbox=$(mktemp -d -t test-hooks-XXXXXX)
trap 'rm -rf "$sandbox"' EXIT
git -C "$sandbox" init -q
git -C "$sandbox" config user.email test@example.invalid
git -C "$sandbox" config user.name test
echo base > "$sandbox/tracked"
git -C "$sandbox" add -A
git -C "$sandbox" commit -qm base

# check <stage|skip> <label> <command>
check() {
  local expect=$1 label=$2 cmd=$3 got=skip

  echo dirty > "$sandbox/tracked"
  git -C "$sandbox" reset -q

  CLAUDE_PROJECT_DIR="$sandbox" bash "$HOOK" >/dev/null 2>&1 \
    <<<"$(jq -nc --arg c "$cmd" '{tool_input: {command: $c}}')"

  git -C "$sandbox" diff --cached --quiet || got=stage

  if [[ $got == "$expect" ]]; then
    printf '  ok    %-42s -> %s\n' "$label" "$got"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-42s -> %s (wanted %s)\n' "$label" "$got" "$expect"
    fail=$((fail + 1))
  fi
}

echo "git-add-before-nix.sh — must stage:"
check stage "plain nix build"           'nix build .#min'
check stage "after &&"                  'git add -A && nix build .#gui'
check stage "after ;"                   'cd /tmp; nix flake check'
check stage "after |"                   'echo x | nix run .#min'
check stage 'inside $( )'               'p=$(nix eval --raw .#min.outPath)'
check stage "nix-shell"                 'nix-shell -p hello'
check stage "verify.sh"                 './scripts/verify.sh build'
check stage "verify.sh after git add"   'git add -A && ./scripts/verify.sh build'
check stage "leading whitespace"        '   nix build .#min'
check stage "second line of a command"  $'git add -A\nnix build .#gui'

echo "git-add-before-nix.sh — must not stage:"
check skip  "commit, heredoc names nix" $'git commit -q -F - <<\'EOF\'\nfeat: thing\n\nopened from inside nix develop, so\nEOF'
check skip  "commit -m names nix"       'git commit -m "resolve from PATH, not nix build"'
check skip  "commit -F file"            'git commit -q -F /tmp/msg.txt'
check skip  "heredoc prose, no commit"  $'cat > f.txt <<\'EOF\'\nrun nix build to check\nEOF'
check skip  "the word mid-sentence"     'echo "we prefer nix build here"'
check skip  "a path under /nix/store"   'ls /nix/store/abc-source'
check skip  "nixpkgs, not nix"          'grep -rn nixpkgs modules/'
check skip  "nixfmt, not nix"           'echo nixfmt-rs'
check skip  "phoenix, not nix"          'echo phoenix rises'
check skip  "unrelated git"             'git log --oneline -5'

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] || echo "A hook that stages during a commit silently widens it. Fix before committing."
exit $((fail > 0))
