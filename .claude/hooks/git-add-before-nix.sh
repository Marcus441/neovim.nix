#!/usr/bin/env bash
# PreToolUse(Bash): flakes see only tracked files. Stage everything before any
# nix evaluation so a freshly written module is visible to the build.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

# Never stage during a commit. `git add -A` here silently widens the commit to
# the whole working tree, which is the opposite of a single-concern commit and
# is never what the caller wanted.
grep -Eq '(^|[;&|(`])[[:space:]]*git[[:space:]]+commit([[:space:]]|$)' <<<"$cmd" && exit 0

# Drop heredoc bodies before looking for a nix invocation. A commit message fed
# in with `-F -` is prose, and prose that names a nix command is not one.
body=$(awk '
  {
    if (indoc) {
      line = $0
      sub(/^[ \t]+/, "", line)
      sub(/[ \t]+$/, "", line)
      if (line == term) indoc = 0
      next
    }
    if (match($0, /<<-?[ \t]*(\047[A-Za-z_][A-Za-z0-9_]*\047|"[A-Za-z_][A-Za-z0-9_]*"|[A-Za-z_][A-Za-z0-9_]*)/)) {
      t = substr($0, RSTART, RLENGTH)
      sub(/^<<-?[ \t]*/, "", t)
      gsub(/\047|"/, "", t)
      term = t
      indoc = 1
    }
    print
  }
' <<<"$cmd")

# Only nix-evaluating commands. `nix` must sit in command position -- start of a
# line or after a separator -- not merely after a space, which matched any
# sentence containing the word.
grep -Eq '(^|[;&|(`])[[:space:]]*(nix|nix-build|nix-instantiate|nix-shell)([[:space:]]|$)' <<<"$body" \
  || grep -q 'verify\.sh' <<<"$body" \
  || exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Nothing unstaged or untracked? Say nothing. `git status --porcelain` is the
# wrong test here: it also reports already-staged work, so it would re-announce
# on every nix command for the whole of a session.
if [ -z "$(git -C "$dir" ls-files --others --exclude-standard)" ] \
   && git -C "$dir" diff --quiet 2>/dev/null; then
  exit 0
fi

if git -C "$dir" add -A; then
  echo "hook: staged working tree with 'git add -A' so the flake can see it."
fi

exit 0
