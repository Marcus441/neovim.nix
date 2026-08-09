---
description: >-
  Use when adding a plugin or a feature to the Neovim config, or extending an
  existing one. Covers choosing an nvf module vs extraPlugins, which aspect it
  belongs to, where its keymap and Lua go, plugin ordering, and verification.
---

# Adding a plugin or feature

## 1. nvf module or `extraPlugins`?

**Check nvf first.** `vim.<category>.<plugin>.enable` with `setupOpts` is the
supported path and survives nvf updates. Search the nvf source for the plugin
name before reaching for `extraPlugins`.

Use `vim.extraPlugins.<name>` only when nvf has no module:

```nix
vim.extraPlugins = {
  vim-dadbod-ui = {
    package = pkgs.vimPlugins.vim-dadbod-ui;
    after = ["vim-dadbod"];
  };
};
```

`after` is the **only** ordering mechanism for these — file position does
nothing. `core/extra-plugins.nix` orders undotree after the theme this way.

## 2. Which aspect?

**Default to `core`. Justify the exception.** `min` is the editor that ships to
every host; `gui` is one program's launcher.

| `core` | `gui` |
| --- | --- |
| options, motions, clipboard, oil, picker, theme | LSP, completion, dashboard, session, statusline |
| treesitter, formatters | anything assuming Neovide, or a big closure |

Two reasons to put a line in `gui`: it **needs a language server**, or it drags a
toolchain-sized closure into `min`. "It feels like an IDE thing" is not one.

**Do not invent a third aspect.** With two variants only `gui` is earned
(CLAUDE.md §3). A plugin nothing declines is `core`.

## 3. One file, every aspect it touches

A feature that behaves differently in the two builds is still **one file**
declaring two memberships:

```nix
{
  flake.modules.nvf.core.vim.utility.oil-nvim.enable = true;
  flake.modules.nvf.gui.vim.utility.oil-nvim.setupOpts.view_options.show_hidden = true;
}
```

Splitting that across `core/oil.nix` and `gui/oil.nix` is the Inv. 3 violation
this whole refactor exists to remove.

## 4. Its keymap and its Lua go with it

The file that installs a plugin owns its keymap and its setup body.
`gui/database.nix` is the right shape: plugins, `luaConfigRC`, and the
`<leader>D` bind in one file. `core/extra-plugins.nix` + the undotree bind in
`core/keymaps/general.nix` is the wrong shape — CLAUDE.md §8 item 8.

Lua goes in via `luaConfigRC.<name>` (a DAG entry, ordered by name and
`entryAfter`) or `extraPlugins.<n>.setup`. A large body belongs in a `.lua` file
read with `builtins.readFile`. See `.claude/rules/lua-in-nix.md` for the `''${`
and column-0 traps, and the two-line cap on comments inside `''`.

## 5. Extending an existing feature

Add a **new file** targeting the same aspect. Do not add an enable flag — split
into two files and let variants differ by aspect. `mkEnableOption` per aspect is
an anti-pattern: variants compose by *taking* aspects, not by enabling them.

Adding a keymap or an autocmd appends to a `listOf`, so it lands in file order
and will move the store path. That is expected; see
`.claude/rules/structural-verification.md` for reading the diff.

## Verify

```bash
./scripts/verify.sh build     # both outputs
nix run .#gui                 # and .#min if the change touched core
```

Then exercise the feature in the editor. A plugin that builds and does not load
is the normal failure; no Nix-level check catches it.

## Before you finish

- Check CLAUDE.md §8 before treating a neighbouring file as an example — today
  most of them are divergences, not exemplars.
- Small, single-concern commit. Rationale in the message, not in comments.
