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

| Prefix        | Category        | Description                                          |
| :------------ | :-------------- | :--------------------------------------------------- |
| `<leader>s`   | **[S]earch**    | Fuzzy find files, grep, help tags, etc. (Telescope)  |
| `<leader>w`   | **[W]orkspace** | Workspace-specific actions.                          |
| `<leader>c`   | **[C]ode**      | LSP actions like code actions and formatting.        |
| `<leader>d`   | **[D]ocument**  | Document-specific actions and diagnostics.           |
| `<leader>r`   | **[R]ename**    | LSP symbol renaming.                                 |
| `<leader>h`   | **[H]unk**      | Git hunks and staging.                               |
| `<leader>t`   | **[T]oggle**    | Toggle UI elements like line numbers or diagnostics. |
| `<leader>u`   | **[U]ndotree**  | Toggle the UndoTree visualization.                   |
| `<leader>sc`  | **[S]ave [C]**  | Save current session.                                |
| `<leader>sl`  | **[S]ave [L]**  | Pick and load a session.                             |
| `<leader>slt` | **[S]ess [L]T** | Load last session.                                   |
| `<leader>sd`  | **[S]ess [D]**  | Delete a session.                                    |
| `<leader>gg`  | **Lazygit**     | Open lazygit in a floating terminal.                 |
| `<A-t>`       | **Terminal**    | Open a floating terminal.                            |

**Pro Tip**: Press `<leader>` and wait for a second to see the `which-key`
popup, which lists all available keybindings and their descriptions.

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, feel
free to open an issue or submit a pull request.

