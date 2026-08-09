# REFACTOR.md — taking this config dendritic

The live plan. **Delete this file when Stage 5 lands** — finished plans go to git
history (CLAUDE.md §10).

`CLAUDE.md` is the contract this works toward and §8 there is the divergence
ledger; each stage below names the items it closes. Every stage is one reviewed
commit ending in `./scripts/verify.sh <previous-commit>`.

## What is wrong today, in one paragraph

`modules/core/` and `modules/gui/` are profile directories: the path says which
build a file belongs to, which is the thing the pattern exists to remove. Four
concerns are consequently split across two files each (`options`, `auto-cmds`,
`languages`, `keymaps/`), so a language costs 2–4 edits and a plugin's keymap
lives away from the plugin. Commits `9f20108`–`8dc5394` are seven fixes' worth
of evidence for the cost.

## Ground rules for every stage

- **Prove it, don't argue it.** `./scripts/verify.sh <prev>` compares store
  paths. Read a FAIL against `.claude/rules/structural-verification.md`.
- **`min` is the control.** A change confined to `gui` must leave `min`
  identical.
- **The gate is "diff is order-only", not "byte-identical".** Stage 0 set the
  precedent and the method: canonicalise every `listOf` region of both
  `init.lua` files by sorting its records, then diff. What survives is real
  content change and must be justified line by line. Store-path equality is
  still the stronger proof when you can get it — `min` did in Stage 0.
- **Do not push.** The consuming flake pins a revision; publishing is the
  human's call, and nothing here reaches the desktop until they make it.
- **Close the §8 item in the same commit** that fixes it.

---

## Stage 1 — dissolve the profile split

Closes §8 items 2 and 4.

Merge each pair into one file declaring both memberships: `options`,
`auto-cmds`, `languages`, and the `keymaps/` trees. `modules/core/` and
`modules/gui/` cease to exist. This is where Inv. 3 and Inv. 4 are actually paid
off.

Expect the store path to move — merging reorders the `listOf` options. Verify the
diff is order-only.

## Stage 2 — per-language files

Closes §8 items 5 and 6.

`modules/languages/<lang>.nix`, one file per language, carrying treesitter, the
formatter, the `core` `lsp.enable = lib.mkDefault false`, the `gui` server
choice, and any `lsp.servers.<name>.cmd` override. Both `languages.nix` files
disappear.

**Resolve `preferPath` first.** It is a `let` binding in `modules/gui/languages.nix:7`
and per-language files cannot reach it. Two candidates — a flake-parts option, or
a `/_` expression consumed by `import`. This is an open question in
`.claude/rules/settled-decisions.md`; ask rather than inventing.

Adding a language after this stage is one file. That is the whole point of the
refactor.

## Stage 3 — break up the grab-bags

Closes §8 items 7 and 9.

`modules/core/options.nix` and `modules/gui/options.nix` each mix
`vim.options` with about eight plugin enables. Split per concern: snacks, mini,
git/gitsigns, diagnostics, oil, borders, comments, and a genuine `options.nix`
holding only `vim.options`.

Normalise `config.vim` vs bare `vim` while here — `modules/core/options.nix` is the only
file using the explicit form.

## Stage 4 — keymaps go with the feature

Closes §8 item 8.

Today undotree's bind is in `modules/core/keymaps/general.nix` while the plugin is in
`modules/core/extra-plugins.nix`; dadbod's bind is inline in `modules/gui/database.nix`. Two
shapes, and only one survives.

`modules/gui/database.nix` is the shape that matches the pattern: the file that installs
a thing owns its keymap. The alternative — keymaps grouped by domain, as a
deliberate intent namespace — is defensible but must then be *all* of them.
**Decide, record it in `.claude/rules/settled-decisions.md`, and apply it
uniformly.**

## Stage 5 — docs, README, cleanup

Closes §8 items 10 and 11 (or records item 11 as deliberately deferred).

1. Rewrite the README's *Structure* section — it still describes `core/ min/ gui/`,
   which no longer exists at all.
2. Populate `docs/conventions/` and `docs/decisions/` with the decisions the
   preceding stages actually made, and add the `# load-bearing:` pointers at the
   values that need them. The known candidates: the `allowUnfreePredicate`, the
   `$PATH` formatter resolution in `core`, `preferPath`'s silent fallback, and
   the `mkDefault`/plain override rule between `core` and `gui`.
3. Confirm `.luarc.json` and `.luacheckrc` are dead — they reference a `lua/`
   layout that no longer exists — then delete them.
4. Delete this file.

## Not in scope

Swapping nvf for anything else; adding `checks`/`formatter`/`devShells` outputs;
splitting `gui` into finer aspects before a third variant earns it. See
`.claude/rules/settled-decisions.md`.
