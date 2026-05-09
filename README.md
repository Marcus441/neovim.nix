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

```
core/       shared config (options, keymaps, theme, formatter, languages/treesitter)
min/        mini.statusline, builtin treesitter grammars
gui/        LSP, blink-cmp, lualine, snacks extras, dashboard, session manager
```

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
| `<leader>L` | Lazygit |
| `<leader>u` | Undotree |
| `<leader>cs` | Scratch buffer |
| `-` | Oil |
| `<leader>y` / `<leader>Y` | Yank to clipboard / yank line |
| `<leader>p` | Paste (void register) |
| `<leader>d` | Delete (void register) |
| `J` / `K` (visual) | Move block down / up |
| `<C-d>` / `<C-u>` | Half page down / up (centered) |
| `n` / `N` | Next / prev match (centered) |
| `<C-=>` / `<C-->` | Neovide scale up / down |
