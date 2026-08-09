#!/usr/bin/env bash
# PostToolUse(Write|Edit): no manual import lists under modules/ (Inv. 5).
# import-tree already loaded every .nix file there; a barrel is a list to forget
# to edit.
#
# Scoped to modules/ on purpose. The pre-refactor barrels in core/ and gui/ are
# CLAUDE.md 8 item 3 and are deleted by REFACTOR.md Stage 0 -- blocking edits to
# them before then would fight the refactor rather than help it.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0
[[ $file == *.nix ]] || exit 0
[ -f "$file" ] || exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
rel=${file#"$dir"/}
[[ $rel == modules/* ]] || exit 0

# An imports list naming a relative path is the violation. A list of flake
# inputs or option values is not.
out=$(awk '
  { line = $0; sub(/#.*/, "", line) }
  line ~ /(^|[^a-zA-Z0-9_.$-])imports[[:space:]]*=/ { inlist = 1; at = NR }
  inlist && line ~ /\.\// {
    printf "%s:%d: imports list naming a relative path\n", FILENAME, at
    bad = 1; inlist = 0; next
  }
  inlist && NR > at && line ~ /\]/ { inlist = 0 }
  END { exit (bad > 0) }
' "$file" 2>/dev/null) || {
  {
    echo "$out"
    echo
    echo "import-tree already loaded every .nix file under modules/, so a manual"
    echo "imports list is a list to forget to edit (CLAUDE.md Inv. 5). Delete it"
    echo "and let discovery do the work. The one permitted central wiring point"
    echo "is modules/variants/generator.nix, which maps over aspect names rather"
    echo "than over paths."
  } >&2
  exit 2
}

exit 0
