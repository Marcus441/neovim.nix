#!/usr/bin/env bash
# PostToolUse(Write|Edit): a comment inside a '' block is a label, not an
# argument. AGENTS.md 10 caps it at two lines.
#
# PostToolUse rather than PreToolUse because the check needs the whole file:
# whether a '--' is a comment at all depends on it sitting inside a '' block,
# and an Edit's new_string alone cannot answer that.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0
[[ $file == *.nix ]] || exit 0
[ -f "$file" ] || exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
awkfile="$dir/.claude/hooks/comment-length.awk"
[ -f "$awkfile" ] || exit 0

out=$(awk -f "$awkfile" "$file" 2>/dev/null) || {
  {
    echo "$out"
    echo
    echo "Text inside a '' block ships into the generated init.lua, so this is"
    echo "content, not a comment. Label what the block produces; do not argue"
    echo "for a value. Two lines is the cap -- a third means it is an argument,"
    echo "and arguments belong in docs/."
  } >&2
  exit 2
}

exit 0
