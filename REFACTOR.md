# REFACTOR.md — taking this config dendritic

The live plan. **Delete this file when Stage 5 lands** — finished plans go to git
history (CLAUDE.md §10).

`CLAUDE.md` is the contract this works toward and §8 there is the divergence
ledger; each stage below names the items it closes. Every stage is one reviewed
commit ending in `./scripts/verify.sh <previous-commit>`.

## What is wrong today, in one paragraph

`core/`, `min/` and `gui/` are profile directories: the path says which build a
file belongs to, which is the thing the pattern exists to remove. Four concerns
are consequently split across two files each (`options`, `auto-cmds`,
`languages`, `keymaps/`), so a language costs 2–4 edits and a plugin's keymap
lives away from the plugin. Four barrel `default.nix` files exist only to list
their siblings. Commits `9f20108`–`8dc5394` are seven fixes' worth of evidence
for the cost.

## Ground rules for every stage

- **Prove it, don't argue it.** `./scripts/verify.sh <prev>` compares store
  paths. Read a FAIL against `.claude/rules/structural-verification.md`.
- **`min` is the control.** A change confined to `gui` must leave `min`
  identical.
- **Do not push.** The consuming flake pins a revision; publishing is the
  human's call, and nothing here reaches the desktop until they make it.
- **Close the §8 item in the same commit** that fixes it.

---

## Stage 0 — skeleton, zero content change

Closes §8 items 1 and 3. **Exit gate: both outputs byte-identical.** This is the
one stage where a FAIL is always a bug, which is why it is its own commit.

1. `flake.nix` becomes a manifest: swap `flake-utils` for `flake-parts`, add
   `import-tree`, keep the same `systems` set that `eachDefaultSystem` produced.
2. Re-establish `pkgs` with its `allowUnfreePredicate` via
   `perSystem._module.args.pkgs` — losing it does not error, roslyn just stops
   building (`.claude/rules/variant-wiring.md`).
3. `modules/aspects.nix` declares `flake.modules.nvf.<aspect>` as
   `deferredModule` plus `aspectRequires`.
4. `modules/variants/{min,gui}.nix` hold aspect lists; `modules/variants/generator.nix`
   maps them to `perSystem.packages.<name>` and keeps `default` aliasing `min`.
5. Every existing file moves under `modules/` **with its body unchanged**,
   wrapped in `flake.modules.nvf.<core|gui> = { … }`. `min/default.nix`'s body
   becomes part of `core` — it is the only file in the `min` build that is not
   `core`, and it declines nothing.
6. Delete the four barrel `default.nix` files.
7. `core/lua/kanagawa-setup.lua` → `modules/lua/kanagawa-setup.lua`. No `/_`
   needed: `import-tree` imports `.nix` only.

Sketch, to be validated rather than pasted:

```nix
# flake.nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [(inputs.import-tree ./modules)];
    };
}
```

**Watch for:** the module order handed to nvf. `vim.augroups`, `vim.autocmds`,
`vim.keymaps` and `vim.treesitter.queries` are `listOf` options that concatenate
in module order, and the old order was `[./core] ++ [./min|./gui]` with each
barrel's `imports` list in *its written order*, not alphabetical. import-tree
walks depth-first alphabetically. **These differ**, and that alone will move the
store path. Reproducing the old order exactly may need file names chosen to sort
that way — or accept the reorder here, verify the diff is order-only, and treat
Stage 0's gate as "diff is order-only" rather than "identical". Decide which
before starting, and record the choice in the commit message.

## Stage 1 — dissolve the profile split

Closes §8 items 2 and 4.

Merge each pair into one file declaring both memberships: `options`,
`auto-cmds`, `languages`, and the `keymaps/` trees. `core/` and `gui/`
directories cease to exist. This is where Inv. 3 and Inv. 4 are actually paid
off.

Expect the store path to move — merging reorders the `listOf` options. Verify the
diff is order-only.

## Stage 2 — per-language files

Closes §8 items 5 and 6.

`modules/languages/<lang>.nix`, one file per language, carrying treesitter, the
formatter, the `core` `lsp.enable = lib.mkDefault false`, the `gui` server
choice, and any `lsp.servers.<name>.cmd` override. Both `languages.nix` files
disappear.

**Resolve `preferPath` first.** It is a `let` binding in `gui/languages.nix:6`
and per-language files cannot reach it. Two candidates — a flake-parts option, or
a `/_` expression consumed by `import`. This is an open question in
`.claude/rules/settled-decisions.md`; ask rather than inventing.

Adding a language after this stage is one file. That is the whole point of the
refactor.

## Stage 3 — break up the grab-bags

Closes §8 items 7 and 9.

`core/options.nix` (102 lines) and `gui/options.nix` (97 lines) each mix
`vim.options` with about eight plugin enables. Split per concern: snacks, mini,
git/gitsigns, diagnostics, oil, borders, comments, and a genuine `options.nix`
holding only `vim.options`.

Normalise `config.vim` vs bare `vim` while here — `core/options.nix` is the only
file using the explicit form.

## Stage 4 — keymaps go with the feature

Closes §8 item 8.

Today undotree's bind is in `core/keymaps/general.nix` while the plugin is in
`core/extra-plugins.nix`; dadbod's bind is inline in `gui/database.nix`. Two
shapes, and only one survives.

`gui/database.nix` is the shape that matches the pattern: the file that installs
a thing owns its keymap. The alternative — keymaps grouped by domain, as a
deliberate intent namespace — is defensible but must then be *all* of them.
**Decide, record it in `.claude/rules/settled-decisions.md`, and apply it
uniformly.**

## Stage 5 — docs, README, cleanup

Closes §8 items 10 and 11 (or records item 11 as deliberately deferred).

1. Rewrite the README's *Structure* section — it still describes `core/ min/ gui/`.
2. Populate `docs/conventions/` and `docs/decisions/` with the decisions the
   preceding stages actually made, and add the `# load-bearing:` pointers at the
   values that need them. The known candidates: the `allowUnfreePredicate`, the
   `$PATH` formatter resolution in `min`, `preferPath`'s silent fallback, and
   the `mkDefault`/plain override rule between `core` and `gui`.
3. Confirm `.luarc.json` and `.luacheckrc` are dead — they reference a `lua/`
   layout that no longer exists — then delete them.
4. Delete this file.

## Not in scope

Swapping nvf for anything else; adding `checks`/`formatter`/`devShells` outputs;
splitting `gui` into finer aspects before a third variant earns it. See
`.claude/rules/settled-decisions.md`.
