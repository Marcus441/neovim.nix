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
      Bash, Assembly, HTML/CSS, Terraform, Typst, Markdown.
  - **Auto-formatting**: Enabled on save for all supported languages.
- **Completion & Snippets**:
  - `nvim-cmp` for intelligent autocompletion.
  - `LuaSnip` for snippet management.
- **UI Enhancements**:
  - `lualine.nvim` for a sleek and informative statusline.
  - `noice.nvim` for a modernized UI (messages, cmdline, and popupmenu).
  - `alpha-nvim` for a custom, functional dashboard.
  - `fidget.nvim` for elegant LSP progress notifications.
  - **Macro Recording Notifications**: Visual feedback when starting and
    stopping macro recording.
  - `indent-blankline.nvim` for clear indentation guides.
  - `markview.nvim` for beautiful markdown previews within the buffer.
- **Utilities**:
  - `Telescope.nvim` for powerful fuzzy finding.
  - `Oil.nvim` for editing the file system like a normal buffer.
  - `Gitsigns.nvim` for real-time Git integration.
  - `Which-key.nvim` for interactive keybinding discovery.
  - `Undotree` for visualizing and navigating your undo history.
  - `Neogen` for quick and easy documentation generation.
  - `nvim-dap` for integrated debugging.
  - `vim-tmux-navigator` for seamless navigation between Neovim and tmux panes.

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
- `languages.nix`: Language-specific settings (LSP, Tree-sitter, Formatters).
- `lsp.nix`: Core LSP configuration.
- `keymaps/`: Modular directory for all keybindings.
- `extraPlugins.nix`: Plugins and configurations not covered by native `nvf`
  modules.
- `dashboard.nix`: Custom Alpha-nvim dashboard layout.
- `autoComplete.nix`: `nvim-cmp` and snippet settings.
- `debugger.nix`: `nvim-dap` configuration.

## ⌨️ Keybindings

The **Leader** key is set to `<Space>`.

| Prefix      | Category       | Description                                          |
| :---------- | :------------- | :--------------------------------------------------- |
| `<leader>s` | **[S]earch**   | Fuzzy find files, grep, help tags, etc. (Telescope)  |
| `<leader>c` | **[C]ode**     | LSP actions like code actions and formatting.        |
| `<leader>d` | **[D]ocument** | Document-specific actions and diagnostics.           |
| `<leader>r` | **[R]ename**   | LSP symbol renaming.                                 |
| `<leader>g` | **[G]it**      | Git status, hunks, and staging.                      |
| `<leader>t` | **[T]oggle**   | Toggle UI elements like line numbers or diagnostics. |
| `<leader>u` | **[U]ndotree** | Toggle the UndoTree visualization.                   |

**Pro Tip**: Press `<leader>` and wait for a second to see the `which-key`
popup, which lists all available keybindings and their descriptions.

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, feel
free to open an issue or submit a pull request.
