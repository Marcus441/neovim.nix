#!/usr/bin/env bash
# Recount how many files declare more than one aspect (CLAUDE.md 2).
# The figure goes stale silently and nothing in the build checks it.
# Files declaring no aspect are not counted.
set -euo pipefail

if [ ! -d modules ]; then
  echo "modules/ does not exist: the tree is still pre-refactor."
  echo "Aspect membership is implied by directory, so there is nothing to count."
  printf '  %-24s %s\n' "core/ (aspect core)" "$(find core -name '*.nix' | wc -l) files"
  printf '  %-24s %s\n' "gui/  (aspect gui)"  "$(find gui  -name '*.nix' | wc -l) files"
  printf '  %-24s %s\n' "min/  (variant)"     "$(find min  -name '*.nix' | wc -l) files"
  echo
  echo "Every one of them declares exactly one aspect, which is the problem."
  echo "See REFACTOR.md Stage 0."
  exit 0
fi

total=0
multi=0
while IFS= read -r f; do
  count=$({ grep -ohE 'flake\.modules\.nvf\.[a-zA-Z0-9_-]+' "$f" || true; } | sort -u | wc -l)
  if [ "$count" -ge 1 ]; then
    total=$((total + 1))
  fi
  if [ "$count" -ge 2 ]; then
    multi=$((multi + 1))
  fi
done < <(find modules -name '*.nix' ! -path '*/_*')

echo "$multi of $total files declare more than one aspect"
