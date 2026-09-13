# neovim.nix

Personal Neovim configuration built with [nvf](https://github.com/notashelf/nvf).
Produces three derivations: a minimal terminal editor (`min`), a terminal
development build with language servers (`full`), and a
[Neovide](https://neovide.github.io) build (`gui`).

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

## Layout

Every `.nix` file under `modules/` is a flake-parts module, auto-imported by
[import-tree](https://github.com/vic/import-tree). nvf modules are stored under
`flake.modules.nvf.<aspect>`, and a package is just a list of aspects.

```
flake.nix               inputs, then import-tree ./modules
modules/
  flake/                flake-parts plumbing: systems, nixpkgs, preferPathExe, packages
  editor/               options, keymaps, clipboard, folds, undo, oil, sessions
  ui/                   statusline, statuscolumn, diagnostics, noice, neovide
  theme/                kanagawa and its highlight overrides
  snacks/               picker, dashboard, notifier, indent guides, images
  lsp/                  lsp, completion, formatting, debugger, trouble
  git/                  gitsigns, fugitive, gitbrowse
  languages/            one file per language; csharp/ and sql/ carry their Lua
```

A file adds to whichever aspects it needs. Each language puts treesitter and its
formatter in `core` and its language server in `dev`:

```nix
{
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.lua = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.dev = {
    vim.languages.lua.lsp.enable = true;
  };
}
```

Where both aspects set an option, `core` uses `lib.mkDefault` and `dev` a plain
value.

## Packages

| Output    | Aspects                | What it is                                                              |
| :-------- | :--------------------- | :---------------------------------------------------------------------- |
| `min`     | `core`                 | terminal editor: options, keymaps, theme, treesitter, formatters        |
| `full`    | `core` `dev` `images`  | adds LSP, completion, debugger, dashboard, sessions and inline images   |
| `gui`     | `core` `dev` `neovide` | `full` without images, plus the Neovide settings                        |
| `default` | `core`                 | alias of `min`                                                          |

The lists live in `modules/flake/packages.nix`.

## Keybindings

Leader is `<Space>`.

| Key                              | Description                                    |
| :------------------------------- | :--------------------------------------------- |
| `gd` / `gD`                      | Definition / declaration                       |
| `gr` / `gI`                      | References / implementation                    |
| `<leader>rn`                     | Rename symbol                                  |
| `<leader>ca`                     | Code action                                    |
| `<leader>ds`                     | Document symbols                               |
| `<leader>e`                      | Expand diagnostic                              |
| `<leader>xx` / `<leader>xX`      | Trouble diagnostics / buffer                   |
| `<leader>sf`                     | Find files                                     |
| `<leader>sg` / `<leader>sw`      | Grep / search word                             |
| `<leader>sd`                     | Diagnostics                                    |
| `<leader>sr` / `<leader>s.`      | Resume / recent files                          |
| `<leader><leader>` / `<leader>/` | Buffers / search in buffer                     |
| `<leader>sh` / `<leader>sk`      | Help / keymaps                                 |
| `<leader>sp` / `<leader>sz`      | Projects / zoxide                              |
| `<leader>sm`                     | Marks                                          |
| `<leader>gs` / `<leader>gb`      | Git status / browse                            |
| `<leader>tf`                     | Toggle format on save                          |
| `<leader>tm` / `<leader>mp`      | Toggle markdown rendering / markdown preview   |
| `<leader>u`                      | Undotree                                       |
| `<leader>D`                      | Database UI                                    |
| `<M-CR>`                         | Execute query (SQL buffers)                    |
| `<leader>S`                      | Execute query (SQL buffers, dadbod-ui default) |
| `<leader>W`                      | Save query (SQL buffers)                       |
| `<leader>E`                      | Edit bind parameters (SQL buffers)             |
| `<leader>cs` / `<leader>cl`      | Trouble symbols / LSP                          |
| `-`                              | Oil                                            |
| `<leader>y` / `<leader>Y`        | Yank to clipboard / yank line                  |
| `<leader>p`                      | Paste (void register)                          |
| `<leader>d`                      | Delete (void register)                         |
| `J` / `K` (visual)               | Move block down / up                           |
| `<C-d>` / `<C-u>`                | Half page down / up (centered)                 |
| `n` / `N`                        | Next / prev match (centered)                   |
| `<C-=>` / `<C-->`                | Neovide scale up / down                        |

## Databases

`<leader>D` opens the dadbod-ui drawer. dadbod-ui turns every `DB_UI_*`
environment variable into a connection named after its lowercased suffix:

```bash
export DB_UI_DEV=postgresql://user:pw@localhost:5432/myapp_dev
export DB_UI_PROD=sqlserver://user:pw@sql.example:1433/myapp
```

`A` in the drawer adds a connection and saves it to
`~/.local/share/db_ui/connections.json`. SQL formatting needs a known dialect: a
query buffer takes it from the connection, a `.sql` file needs
`vim.g.sql_dialect` or a `.sqruff` in the project.
