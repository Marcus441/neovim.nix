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
nothing, and it resolves across files: `modules/undo.nix` orders undotree after
the `theme-plugin` that `modules/kanagawa.nix` declares.

## 2. Which aspect?

**Default to `core`. Justify the exception.** `min` is the editor that ships to
every host; `gui` is one program's launcher.

| `core` | `dev` |
| --- | --- |
| options, motions, clipboard, oil, picker, theme | LSP, completion, dashboard, session, statusline |
| treesitter, formatters | anything assuming Neovide, or a big closure |

Two reasons to put a line in `dev`: it **needs a language server**, or it drags a
toolchain-sized closure into `min`. "It feels like an IDE thing" is not one.

**Do not invent a fifth aspect.** `dev`, `neovide` and `images` are earned
because a variant declines each (AGENTS.md §3). A plugin nothing declines is
`core`; a Neovide-only fact is `neovide`; terminal image rendering is `images`.

## 3. One file, every aspect it touches

A feature that behaves differently in the two builds is still **one file**
declaring two memberships:

```nix
{
  flake.modules.nvf.core.vim.utility.oil-nvim.enable = true;
  flake.modules.nvf.dev.vim.utility.oil-nvim.setupOpts.view_options.show_hidden = true;
}
```

Splitting that across a `core` file and a `dev` file is the Inv. 3 violation this
whole refactor exists to remove.

## 4. Its keymap and its Lua go with it

The file that installs a plugin owns its keymap and its setup body. This is
settled — see `.claude/rules/settled-decisions.md`. `modules/database.nix` is the
canonical shape: plugins, `luaConfigRC`, and the `<leader>D` bind in one file.
`modules/undo.nix` is the same shape for `undotree`.

A bind that no file installs — a motion, a register trick — is its own concern
and gets its own file (`modules/movement.nix`, `modules/search.nix`). **Do not
recreate a `modules/keymaps/` directory**; grouping binds by mechanism is what
`d53d10b` removed.

Lua goes in via `luaConfigRC.<name>` (a DAG entry, ordered by name and
`entryAfter`) or `extraPlugins.<n>.setup`. A large body belongs in a `.lua` file
read with `builtins.readFile`. See `.claude/rules/lua-in-nix.md` for the `''${`
and column-0 traps, and the two-line cap on comments inside `''`.

## 5. Extending an existing feature

Add a **new file** targeting the same aspect. Do not add an enable flag — split
into two files and let variants differ by aspect. `mkEnableOption` per aspect is
an anti-pattern: variants compose by *taking* aspects, not by enabling them.

**A plugin that is really a suite gets a base file plus one sibling per facet**,
named `<plugin>-<facet>.nix` and flat — `snacks.nix` holds `enable` and the
toggles that are nothing but a boolean, while `snacks-picker.nix`,
`snacks-indent.nix`, `snacks-notifier.nix`, `snacks-gitbrowse.nix`,
`snacks-zen.nix` and `snacks-dashboard.nix` each own a facet and its keymaps.
This is the shape `~/.dotfiles/flake` uses for the same problem (`hyprland.nix`
beside `hyprland-binds.nix`, `hyprland-rules.nix`). Do **not** name the facet
after the capability alone — a bare `picker.nix` does not say what provides it —
and do not let the base file grow back into a list of toggles.

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

- Check AGENTS.md §8 before treating a neighbouring file as an example — today
  most of them are divergences, not exemplars.
- Small, single-concern commit. Rationale in the message, not in comments.
