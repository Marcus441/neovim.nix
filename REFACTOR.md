# REFACTOR.md — taking this config dendritic

The live plan. **Delete this file when Stage 5 lands** — finished plans go to git
history (CLAUDE.md §10).

`CLAUDE.md` is the contract this works toward and §8 there is the divergence
ledger; each stage below names the items it closes. Every stage is one reviewed
commit ending in `./scripts/verify.sh <previous-commit>`.

## What is wrong today, in one paragraph

The structure is right and the decomposition is not. Stage 1 dissolved the
profile directories, so no path encodes a variant any more — but three files
still hold everything. `modules/languages.nix` is every language at once,
`modules/options.nix` mixes `vim.options` with sixteen plugin enables, and
`modules/keymaps/` groups binds by domain while `modules/database.nix` keeps its
own. So a language still costs three edits inside one file, and a plugin's keymap
still lives away from the plugin. Commits `9f20108`–`8dc5394` are seven fixes'
worth of evidence for the cost.

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
  three outputs did in Stage 1. **Do not budget for a reorder you have not
  measured:** only same-aspect relative order matters, so interleaving two
  already-alphabetical sequences permutes nothing.
- **Do not push.** The consuming flake pins a revision; publishing is the
  human's call, and nothing here reaches the desktop until they make it.
- **Close the §8 item in the same commit** that fixes it.

---

## Stage 2 — per-language files

Closes §8 items 5 and 6.

`modules/languages/<lang>.nix`, one file per language, carrying treesitter, the
formatter, the `core` `lsp.enable = lib.mkDefault false`, the `gui` server
choice, and any `lsp.servers.<name>.cmd` override. `modules/languages.nix`
disappears.

**Resolve `preferPath` first.** It is a `let` binding in `modules/languages.nix:65`
and per-language files cannot reach it. Two candidates — a flake-parts option, or
a `/_` expression consumed by `import`. This is an open question in
`.claude/rules/settled-decisions.md`; ask rather than inventing.

Adding a language after this stage is one file. That is the whole point of the
refactor.

## Stage 3 — break up the grab-bags

Closes §8 items 7 and 9.

Both halves of `modules/options.nix` mix `vim.options` with about eight plugin
enables each. Split per concern: snacks, mini, git/gitsigns, diagnostics, oil,
borders, comments, and a genuine `options.nix` holding only `vim.options`. Each
resulting file carries both aspects where both have something to say — snacks in
particular is split across the two halves today.

Normalise `config.vim` vs bare `vim` while here — `modules/options.nix` is the
only file using the explicit form.

## Stage 4 — keymaps go with the feature

Closes §8 item 8.

Today undotree's bind is in `modules/keymaps/general.nix` while the plugin is in
`modules/extra-plugins.nix`; dadbod's bind is inline in `modules/database.nix`. Two
shapes, and only one survives.

`modules/database.nix` is the shape that matches the pattern: the file that installs
a thing owns its keymap. The alternative — keymaps grouped by domain, as a
deliberate intent namespace — is defensible but must then be *all* of them.
**Decide, record it in `.claude/rules/settled-decisions.md`, and apply it
uniformly.**

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
