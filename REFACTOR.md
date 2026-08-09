# REFACTOR.md — taking this config dendritic

The live plan. **Delete this file when Stage 5 lands** — finished plans go to git
history (CLAUDE.md §10).

`CLAUDE.md` is the contract this works toward and §8 there is the divergence
ledger; each stage below names the items it closes. Every stage is one reviewed
commit ending in `./scripts/verify.sh <previous-commit>`.

## What is wrong today, in one paragraph

Nothing structural. Stage 1 dissolved the profile directories, Stage 2 made a
language one file, Stage 3 broke up the `options.nix` grab-bag — the refactor's
stated point — and Stage 4 put every keymap in the file that installs its
feature. What is left is documentation the earlier stages outran, and two dead
config files.

## Ground rules for every stage

- **Prove it, don't argue it.** `./scripts/verify.sh <prev>` compares store
  paths. Read a FAIL against `.claude/rules/structural-verification.md`.
- **`min` is the control.** A change confined to `gui` must leave `min`
  identical.
- **The gate is "diff is order-only", not "byte-identical".** Stage 0 set the
  precedent and the method: canonicalise every `listOf` region of both
  `init.lua` files by sorting its records, then diff. What survives is real
  content change and must be justified line by line. Store-path equality is
  still the stronger proof when you can get it — `min` did in Stage 0, and all
  three outputs did in Stages 1 and 2. **Do not budget for a reorder you have not
  measured:** only same-aspect relative order matters, and a `listOf` with one
  contributing file cannot be permuted by splitting the files around it.
- **Do not push.** The consuming flake pins a revision; publishing is the
  human's call, and nothing here reaches the desktop until they make it.
- **Close the §8 item in the same commit** that fixes it.

---

## Stage 5 — docs and cleanup

Closes §8 items 10 and 11 (or records item 11 as deliberately deferred).

1. Populate `docs/conventions/` and `docs/decisions/` with the decisions the
   preceding stages actually made, and add the `# load-bearing:` pointers at the
   values that need them. The known candidates: the `allowUnfreePredicate`, the
   `$PATH` formatter resolution in `core`, `preferPath`'s silent fallback, and
   the `mkDefault`/plain override rule between `core` and `gui`.
2. Confirm `.luarc.json` and `.luacheckrc` are dead — they reference a `lua/`
   layout that no longer exists — then delete them.
3. Re-check the README against the tree the earlier stages left. Its *Structure*
   section was rewritten when Stage 1 landed; Stages 2–4 move files it names.
4. Delete this file.

## Not in scope

Swapping nvf for anything else; adding `checks`/`formatter`/`devShells` outputs;
splitting `gui` into finer aspects before a third variant earns it. See
`.claude/rules/settled-decisions.md`.
