# neovim

Neovim configuration built with [nvf](https://github.com/notashelf/nvf).

## Usage

Run directly:

```bash
nix run github:yourusername/neovim-config
```

Or add to your NixOS/Home Manager config:

```nix
inputs.my-neovim.url = "github:yourusername/neovim-config";
environment.systemPackages = [ inputs.my-neovim.packages.${pkgs.system}.default ];
```

## Structure

- `flake.nix` — entry point
- `config/languages.nix` — LSP, treesitter, formatters
- `config/lsp.nix` — LSP and diagnostics
- `config/options.nix` — global options, UI, utilities
- `config/extraPlugins.nix` — kanagawa, undotree
- `config/keymaps/` — keybindings
- `config/formatter.nix` — conform.nvim

## Keybindings

Leader is `<Space>`.

| Key | Description |
| :-- | :---------- |
| `<Esc>` | Clear search highlights |
| `<leader>u` | Undotree |
| `<leader>gs` | Git status |
| `gd` / `gD` | Goto definition / declaration |
| `gr` / `gI` | Goto references / implementation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>ds` | Document symbols |
| `<leader>sf` | Find files |
| `<leader>sg` | Grep |
| `<leader>sw` | Search word under cursor |
| `<leader>sd` | Search diagnostics |
| `<leader>sr` | Resume last search |
| `<leader>s.` | Recent files |
| `<leader><leader>` | Find buffers |
| `<leader>/` | Search in buffer |
| `<leader>sh` / `<leader>sk` | Help / keymaps |
| `<leader>sp` / `<leader>sz` | Projects / zoxide |
| `<leader>y` / `<leader>Y` | Yank to clipboard / yank line |
| `<leader>p` | Paste from void register |
| `<leader>d` | Delete to void register |
| `<leader>cs` | Scratch buffer |
| `-` | Oil |
| `K` | Hover docs |
| `J` | Join line |
| `<C-d>` / `<C-u>` | Half page down/up (centered) |
| `n` / `N` | Next/prev match (centered) |
| `J` / `K` (visual) | Move block down/up |
