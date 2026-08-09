#!/usr/bin/env bash
# PreToolUse(Bash): refuse `nix flake update`, which moves existing pins.
# Adding an input and running `nix flake lock` is fine.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

if grep -Eq '(^|[|;&([:space:]])nix[[:space:]]+flake[[:space:]]+update' <<<"$cmd"; then
  echo "Blocked: nix flake update moves existing pins. Add inputs and run nix flake lock instead." >&2
  exit 2
fi

exit 0
