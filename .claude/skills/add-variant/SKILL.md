---
description: >-
  Use when adding a new build variant (a new packages.<name> output), changing a
  variant's aspect list, or deciding whether a new aspect is earned. Covers the
  variant record, the frozen output names, aspect ordering, and when a new
  variant earns a new aspect.
---

# Adding a variant

A variant is a **list of aspects** and nothing else. Machine facts, user
preferences and conditionals do not live here — aspects are variant-agnostic
(Inv. 6).

```nix
# modules/variants/<name>.nix
{
  variants.<name>.aspects = [ "core" "dev" ];
}
```

The generator turns each record into `perSystem.packages.<name>`.

## The output names are public API

`~/.dotfiles/flake` pins this flake and reads `packages.${system}.min` and
`.gui`; `default` aliases `min`; `full` is exported for terminal development
and consumed by nothing yet. **Adding** a name is a cheap,
backwards-compatible API addition. **Renaming or removing** one breaks the
desktop, at the consumer's next input update, with an error naming this flake
rather than the reason.

Local edits do not reach the machine — the consumer pins a revision, not this
working tree. Pushing and updating that input is the human's call.

## A new variant is what earns a new aspect

This is the point of the exercise. An aspect is earned only when some variant
declines it (AGENTS.md §3). A new variant is the event that justifies a split —
**split at the seam the new variant declines**, not along tidy-looking category
lines. That is how the current table came to be:

```
min     [ core ]
full    [ core dev ]
gui     [ core dev neovide ]
```

`dev` is earned because `min` declines it; `neovide` because `full` — a terminal
build — declines it. The `full` variant and the `neovide` aspect arrived in the
same commit, because a split with no variant exercising the seam is structure
without a decision behind it, and the anti-pattern table rejects it. A further
split of `dev` (into `lsp`/`ui`/`db`, say) waits for a variant that declines one
of the pieces.

If the new variant declines nothing that exists — it is just `core` plus one
setting — it may not need an aspect at all. Ask whether it needs to be a variant
rather than a `setupOpts` difference.

## Aspect order is load-bearing

The list is the module order handed to nvf. `vim.augroups`, `vim.autocmds`,
`vim.keymaps` and `vim.treesitter.queries` are `listOf` options that concatenate
in that order, and that order reaches the generated `init.lua` and the store
path. **When splitting an aspect, put the new names where the old one sat.**

Measure with `scripts/verify.sh`; do not predict.

## `aspectRequires`

When an aspect only makes sense alongside another, declare it in the file that
creates the dependency — not in a central table, which drifts as files stop
reading each other. The generator rejects a variant that leaves one unmet, naming
the variant and the aspect. Without it, the failure is a build that succeeds and
behaves subtly wrong.

## Verify

```bash
./scripts/verify.sh build     # every output, including the new one
nix run .#<name>
```

Adding a variant must leave the existing outputs **byte-identical** —
`./scripts/verify.sh HEAD~1` should PASS on every pre-existing output. If it doesn't, the
new record changed shared state instead of composing existing aspects.

## Before you finish

- The new name is documented in `README.md` and in AGENTS.md's variant table.
- `default` still aliases `min`.
- Small, single-concern commit.
