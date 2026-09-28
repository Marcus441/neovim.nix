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
  flake/                flake-parts plumbing: systems, nixpkgs, formatter, packages
  editor/               options, keymaps, which-key, clipboard, folds, undo, oil, sessions
  ui/                   statusline, diagnostics, icons, colorizer, neovide
  theme/                kanagawa
  snacks/               picker, notifier, indent guides, images
  lsp/                  lspconfig, completion, formatting, linting, debugger, trouble
  git/                  gitsigns, fugitive, gitbrowse
  languages/            one file per language; csharp/ and sql/ carry their Lua
```

A file adds to whichever aspects it needs. Each language puts treesitter and its
formatter in `core`, and its language server and pinned tools in `dev`:

```nix
{
  flake.modules.nvf.core = {
    vim = {
      languages.lua.enable = true;
      formatter.conform-nvim.setupOpts.formatters_by_ft.lua = [ "stylua" ];
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.lua_ls.enable = true;

        extraPackages = [
          pkgs.lua-language-server
          pkgs.stylua
        ];
      };
    };
}
```

## Tools

Language servers, formatters and linters are run by name, so whatever the shell
provides wins. `vim.extraPackages` is appended to `PATH`, which makes the pinned
package the fallback. `min` pins nothing and only uses what the shell has.

Server definitions come from
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), formatters from
[conform.nvim](https://github.com/stevearc/conform.nvim) and linters from
[nvim-lint](https://github.com/mfussenegger/nvim-lint). Nix is formatted with
`nixfmt`, in the editor and through `nix fmt`.

## Packages

| Output    | Aspects                | What it is                                                       |
| :-------- | :--------------------- | :--------------------------------------------------------------- |
| `min`     | `core`                 | terminal editor: options, keymaps, theme, treesitter, formatters |
| `full`    | `core` `dev` `images`  | adds LSP, completion, linting, debugger, sessions, inline images |
| `gui`     | `core` `dev` `neovide` | `full` without images, plus the Neovide settings                 |
| `default` | `core`                 | alias of `min`                                                   |

The lists live in `modules/flake/packages.nix`.

## Keybindings

Leader is `<Space>`. LSP keys follow the Neovim defaults.

| Key                              | Description                                    |
| :------------------------------- | :--------------------------------------------- |
| `<leader>?`                      | Show buffer keymaps (which-key)                |
| `<leader>tk`                     | Toggle the which-key popup                     |
| `gd` / `gD`                      | Definition / declaration                       |
| `grr` / `gri` / `grt`            | References / implementation / type definition  |
| `grn` / `gra`                    | Rename symbol / code action                    |
| `gO` / `gW`                      | Document / workspace symbols                   |
| `K` / `<C-w>d`                   | Hover / diagnostic under cursor                |
| `[d` / `]d`                      | Previous / next diagnostic                     |
| `<leader>xx` / `<leader>xX`      | Trouble diagnostics / buffer                   |
| `<leader>xt`                     | Trouble todos                                  |
| `<leader>xL` / `<leader>xQ`      | Trouble location list / quickfix               |
| `<leader>cs` / `<leader>cl`      | Trouble symbols / LSP                          |
| `<leader>sf`                     | Find files                                     |
| `<leader>sg` / `<leader>sw`      | Grep / search word                             |
| `<leader>sd` / `<leader>st`      | Diagnostics / todos                            |
| `<leader>sr` / `<leader>s.`      | Resume / recent files                          |
| `<leader><leader>` / `<leader>/` | Buffers / search in buffer                     |
| `<leader>sh` / `<leader>sk`      | Help / keymaps                                 |
| `<leader>sp` / `<leader>sz`      | Projects / zoxide                              |
| `<leader>sm`                     | Marks                                          |
| `<leader>gs` / `<leader>gb`      | Git status / browse                            |
| `]c` / `[c`                      | Next / previous hunk                           |
| `<leader>hs` / `<leader>hr`      | Stage / reset hunk                             |
| `<leader>hP` / `<leader>hb`      | Preview hunk / blame line                      |
| `<leader>tb` / `<leader>td`      | Toggle line blame / deleted lines              |
| `<leader>tf`                     | Toggle format on save                          |
| `<leader>tm` / `<leader>tp`      | Toggle markdown rendering / markdown preview   |
| `<leader>ti` / `<leader>tw`      | Toggle indent guides / LSP word highlights     |
| `<leader>tD`                     | Toggle dimming                                 |
| `<leader>ql` / `<leader>qs`      | Load last session / pick a session             |
| `<leader>qw` / `<leader>qd`      | Save / delete session                          |
| `<F5>` / `<leader>b`             | Debugger continue / toggle breakpoint          |
| `<F10>` / `<F11>` / `<F12>`      | Debugger step over / into / out                |
| `<C-n>` / `<C-p>` / `<CR>`       | Completion next / previous / accept            |
| `<leader>u`                      | Undotree                                       |
| `<leader>D`                      | Database UI                                    |
| `<M-CR>`                         | Execute query (SQL buffers)                    |
| `<leader>S`                      | Execute query (SQL buffers, dadbod-ui default) |
| `<leader>W`                      | Save query (SQL buffers)                       |
| `<leader>E`                      | Edit bind parameters (SQL buffers)             |
| `-`                              | Oil                                            |
| `<leader>d`                      | Delete (void register)                         |
| `J` / `K` (visual)               | Move block down / up                           |
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
