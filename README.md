# Marcus' Neovim Configuration

A highly modular and performant Neovim configuration built with
[Nix](https://nixos.org/) and [nvf](https://github.com/notashelf/nvf). Designed
for a seamless developer experience with built-in LSP, Treesitter, and a modern
UI.

## 🚀 Overview

This configuration leverages the power of Nix to manage Neovim and its entire
plugin ecosystem hermetically. It's built on top of the `nvf` framework, which
provides a structured and reproducible way to define Neovim configurations using
Nix modules.

## ✨ Features

- **Theme**: [Kanagawa Dragon](https://github.com/rebelot/kanagawa.nvim) with a
  transparent background for a clean, focused look.
- **Language Support**:
  - Full LSP, Treesitter, and Formatter support for:
    - **Languages**: Nix, Rust, Python, TypeScript/JavaScript, C/C++, C#, Lua,
      Bash, Assembly, HTML/CSS, Markdown, Terraform, Typst.
  - **Auto-formatting**: Enabled on save for all supported languages via Conform.
- **Completion & Snippets**:
  - `blink-cmp` for intelligent autocompletion with LSP, snippets, path, buffer,
    ripgrep, and spell sources.
  - `LuaSnip` for snippet management with friendly snippets.
- **UI Enhancements**:
  - `lualine.nvim` for a sleek and informative statusline.
  - `noice.nvim` for a modernized UI (messages, cmdline, and popupmenu).
  - `alpha-nvim` for a custom, functional dashboard.
  - `fidget.nvim` for elegant LSP progress notifications.
  - `snacks-nvim` for modern UI utilities including image preview, fancy
    notifications, and picker integrations.
  - `mini.indentscope` for visual indentation scope indicators.
  - `indent-blankline.nvim` for clear indentation guides.
  - `markview.nvim` for beautiful markdown previews within the buffer.
  - `smartcolumn` for dynamic column guides.
  - `nvim-highlight-undo` for visual undo highlighting.
  - `nvim-colorizer` for inline color preview.
  - `vim-visual-multi` / `mini.ai` for enhanced text objects.
- **Terminal Integration**:
  - `toggleterm.nvim` for integrated terminal sessions.
  - `lazygit` integration via toggleterm (`<leader>gg`).
- **Utilities**:
  - `Telescope.nvim` for powerful fuzzy finding.
  - `Oil.nvim` for editing the file system like a normal buffer.
  - `Gitsigns.nvim` for real-time Git integration.
  - `Which-key.nvim` for interactive keybinding discovery.
  - `Undotree` for visualizing and navigating your undo history.
  - `Neogen` for quick and easy documentation generation.
  - `nvim-dap` for integrated debugging.
  - `vim-tmux-navigator` for seamless navigation between Neovim and tmux panes.
  - `diffview-nvim` for advanced diff viewing.
  - `direnv` integration for automatic environment loading.
  - `icon-picker` for inserting icons and emojis.
  - `nvim-session-manager` for session management.
  - `project-nvim` for project detection and management.
  - `todo-comments` for TODO/FIXME/NOTE annotations.
  - `comment-nvim` for smart commenting.
  - `nvim-illuminate` for word highlighting.
- **LSP & Diagnostics**:
  - `trouble.nvim` for enhanced LSP diagnostics display.
  - Virtual lines and text diagnostics.
  - Sign-based diagnostics with severity sorting.

## 🛠️ Installation & Usage

### Prerequisites

- [Nix](https://nixos.org/download.html) with Flakes enabled.

### Run Directly

You can try out this configuration without installing it:

```bash
nix run github:yourusername/neovim-config
```

### Integrate into your Nix Configuration

To include it in your NixOS or Home Manager configuration:

1. **Add to your flake inputs**:

   ```nix
   inputs.my-neovim.url = "github:yourusername/neovim-config";
   ```

2. **Add the package to your environment**:

   ```nix
   environment.systemPackages = [
     inputs.my-neovim.packages.${pkgs.system}.default
   ];
   ```

## 📂 Project Structure

The configuration is organized into modular Nix files:

- `flake.nix`: The entry point for the flake, defining the final Neovim package.
- `config/languages.nix`: Language-specific settings (LSP, Tree-sitter, Formatters).
- `config/lsp.nix`: Core LSP configuration (Trouble, format on save).
- `config/options.nix`: Global options, UI, diagnostics, statusline, utilities.
- `config/autoComplete.nix`: `blink-cmp` completion settings.
- `config/extraPlugins.nix`: Plugins and configurations not covered by native `nvf`
  modules (Kanagawa, vim-tmux-navigator, Undotree, Neogen).
- `config/keymaps/`: Modular directory for all keybindings.
- `config/dashboard.nix`: Custom Alpha-nvim dashboard layout.
- `config/terminal.nix`: ToggleTerm and lazygit configuration.
- `config/sessions.nix`: Session management with nvim-session-manager.
- `config/formatter.nix`: Conform.nvim formatter configuration.

## ⌨️ Keybindings

The **Leader** key is set to `<Space>`.

### Quick Reference

| Keybinding         | Category                 | Description                              |
| :----------------- | :----------------------- | :--------------------------------------- |
| `<Esc>`            | Clear search             | Clear search highlights                  |
| `<leader>u`        | [U]ndotree               | Toggle UndoTree visualization            |
| `<C-m>`            | Markview                 | Toggle Markdown preview                  |
| `J`                | Join                     | Join line and keep cursor position       |
| `<C-d>`            | Page                     | Half page down and center                |
| `<C-u>`            | Page                     | Half page up and center                  |
| `n` / `N`          | Search                   | Next/previous match and center           |
| `J` / `K` (v)      | Visual                   | Move visual block down/up                |
| `gd`               | [G]oto [D]efinition      | Goto Definition                          |
| `gD`               | [G]oto [D]eclaration     | Goto Declaration                         |
| `gr`               | [G]oto [R]eferences      | Goto References                          |
| `gI`               | [G]oto [I]mplementation  | Goto Implementation                      |
| `<leader>D`        | Type [D]efinition        | Goto Type Definition                     |
| `<leader>ds`       | [D]oc [S]ymbols          | Document Symbols                         |
| `<leader>ws`       | [W]s [S]ymbols           | Workspace Symbols                        |
| `<leader>rn`       | [R]e[n]ame               | LSP Rename symbol                        |
| `<leader>ca`       | [C]ode [A]ction          | Code Action                              |
| `<leader>sh`       | [S]earch [H]elp          | Help tags                                |
| `<leader>sk`       | [S]earch [K]eymaps       | Keymaps                                  |
| `<leader>sf`       | [S]earch [F]iles         | Files                                    |
| `<leader>ss`       | [S]earch [S]elect Picker | Select Picker                            |
| `<leader>sp`       | [S]earch [P]rojects      | Projects                                 |
| `<leader>sm`       | [S]earch [M]arks         | Marks                                    |
| `<leader>sw`       | [S]earch current [W]ord  | Search word under cursor                 |
| `<leader>sg`       | [S]earch by [G]rep       | Grep                                     |
| `<leader>sd`       | [S]earch [D]iagnostics   | Diagnostics                              |
| `<leader>sr`       | [S]earch [R]esume        | Resume last picker                       |
| `<leader>s.`       | [S]earch [.]Recent       | Recent Files                             |
| `<leader>/`        | [/] Search               | Search in current buffer                 |
| `<leader><leader>` | [ ] Buffers              | Find existing buffers                    |
| `<leader>xx`       | Diagnostics              | Toggle Diagnostics (Trouble)             |
| `<leader>xX`       | Buffer Diags             | Toggle Buffer Diagnostics                |
| `<leader>cs`       | [C]hange [S]ymbols       | Toggle Symbols                           |
| `<leader>cl`       | [C]hange [L]ist          | LSP Definitions/references               |
| `<leader>xL`       | Location List            | Toggle Location List                     |
| `<leader>xQ`       | Quickfix List            | Toggle Quickfix List                     |
| `<leader>tt`       | [T]oggle [T]erminal      | Toggle Terminal                          |
| `<leader>tl`       | [T]oggle [L]azygit       | Toggle Lazygit                           |
| `<leader>ee`       | [E]xplorer               | Toggle File Explorer                     |
| `<leader>er`       | [E]xplorer [R]eveal      | Reveal current file                      |
| `<leader>y`        | Yank                     | Yank to system clipboard                 |
| `<leader>Y`        | Yank line                | Yank line to system clipboard            |
| `<leader>p` (v)    | Paste                    | Paste into void register                 |
| `<leader>d`        | Delete                   | Delete to void register                  |
| `<leader>gs`       | [G]it [S]tatus           | Show Git status                          |
| `-`                | Oil                      | Toggle Oil (file explorer)               |
| `<leader>nf`       | [N]eogen                 | Generate Annotation                      |
| `<C-h/j/k/l>`      | Focus                    | Navigate tmux panes (left/down/up/right) |
| `<Esc><Esc>` (t)   | Terminal                 | Exit terminal mode                       |
| `<C-=>`            | Scale                    | Increase window scale                    |
| `<C-->`            | Scale                    | Decrease window scale                    |

**Pro Tip**: Press `<leader>` and wait for a second to see the `which-key`
popup, which lists all available keybindings and their descriptions.

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, feel
free to open an issue or submit a pull request.
