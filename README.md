# neovim.nix

Personal Neovim configuration built with [nvf](https://github.com/notashelf/nvf).
Produces two derivations: a minimal terminal editor (`min`) and a full IDE build for [Neovide](https://neovide.github.io) (`gui`).

## Installation

```nix
# flake.nix
inputs.neovim-config = {
  url = "github:Marcus441/neovim.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# home.nix
{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  neovim = inputs.neovim-config.packages.${system};
in {
  home.packages = [ neovim.min ];

  programs.neovide = {
    enable = true;
    settings.neovim-bin = "${neovim.gui}/bin/nvim";
  };
}
```

## Structure

Every `.nix` file under `modules/` is a [flake-parts](https://github.com/hercules-ci/flake-parts)
module, discovered by [import-tree](https://github.com/vic/import-tree) — nothing
is imported by hand except the variant wiring. A file is named after a *feature*,
never after a build, and says which **aspects** it belongs to:

```nix
# modules/statusline.nix — one concern, one aspect
{
  flake.modules.nvf.gui = {
    vim = {
      mini.statusline.enable = false;
      statusline.lualine = {
        enable = true;
        theme = "auto";
      };
    };
  };
}
```

A concern that differs between builds is still **one file**, declaring both
memberships — each `modules/languages/<lang>.nix` puts `enable`, treesitter and
the formatter in `core`, and the LSP server and diagnostics in `gui`. Those
attribute sets merge, so a feature grows by adding a file rather than by editing
a list, and adding a language means adding exactly one file.

`modules/variants/` is the only place that names a build. Each variant is an
aspect list, and nothing else:

| Output | Aspects | What it is |
| :--- | :--- | :--- |
| `min` | `core` | terminal editor — options, keymaps, theme, treesitter, formatters, mini.statusline |
| `default` | `core` | alias of `min` |
| `gui` | `core` `gui` | adds LSP, blink-cmp, lualine, snacks extras, dashboard, session manager |

Two derivations, three names. Directories such as `modules/languages/` are
navigation only — they carry no meaning for the module system. A plugin's keymap
lives in the file that installs the plugin, not in a keymap directory.

## Keybindings

Leader is `<Space>`.

| Key | Description |
| :-- | :---------- |
| `gd` / `gD` | Definition / declaration |
| `gr` / `gI` | References / implementation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>ds` | Document symbols |
| `<leader>xx` / `<leader>xX` | Trouble diagnostics / buffer |
| `<leader>sf` | Find files |
| `<leader>sg` / `<leader>sw` | Grep / search word |
| `<leader>sd` | Diagnostics |
| `<leader>sr` / `<leader>s.` | Resume / recent files |
| `<leader><leader>` / `<leader>/` | Buffers / search in buffer |
| `<leader>sh` / `<leader>sk` | Help / keymaps |
| `<leader>sp` / `<leader>sz` | Projects / zoxide |
| `<leader>sm` | Marks |
| `<leader>gs` / `<leader>gb` | Git status / browse |
| `<leader>u` | Undotree |
| `<leader>cs` / `<leader>cl` | Trouble symbols / LSP |
| `-` | Oil |
| `<leader>y` / `<leader>Y` | Yank to clipboard / yank line |
| `<leader>p` | Paste (void register) |
| `<leader>d` | Delete (void register) |
| `J` / `K` (visual) | Move block down / up |
| `<C-d>` / `<C-u>` | Half page down / up (centered) |
| `n` / `N` | Next / prev match (centered) |
| `<C-=>` / `<C-->` | Neovide scale up / down |
