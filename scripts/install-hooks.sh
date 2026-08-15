#!/usr/bin/env bash
# Point this clone at the tracked hooks in .githooks/.
#
#   ./scripts/install-hooks.sh
#
# core.hooksPath is per-clone local config: it lives in .git/config, which is
# not carried by a clone or a fetch. Tracking the hooks makes them survive a
# clone; this makes them run. Once per checkout, and idempotent.
set -uo pipefail

REPO=$(git rev-parse --show-toplevel) || exit 2
cd "$REPO" || exit 2

[ -d .githooks ] || { echo "error: $REPO/.githooks does not exist"; exit 2; }

# Executable bit is tracked, but a checkout with core.fileMode=false or an
# unpacked archive can lose it, and git silently skips a non-executable hook.
for hook in .githooks/*; do
  [ -f "$hook" ] || continue
  [ -x "$hook" ] || chmod +x "$hook"
done

current=$(git config --local --get core.hooksPath || true)
if [ "$current" = ".githooks" ]; then
  echo "hooks: core.hooksPath is already .githooks"
else
  git config --local core.hooksPath .githooks || exit 2
  if [ -n "$current" ]; then
    echo "hooks: core.hooksPath $current -> .githooks"
  else
    echo "hooks: core.hooksPath -> .githooks"
  fi
fi

echo
echo "active:"
for hook in .githooks/*; do
  [ -f "$hook" ] || continue
  printf '  %-14s %s\n' "$(basename "$hook")" "$([ -x "$hook" ] && echo executable || echo "NOT EXECUTABLE")"
done
echo
echo "Verify them with ./scripts/test-githooks.sh."
