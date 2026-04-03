{pkgs, ...}: {
  vim.extraPlugins = {
    theme-plugin = {
      package = pkgs.vimPlugins.kanagawa-nvim;
      setup = "
        local is_neovide = vim.g.neovide ~= nil
        if is_neovide then
          vim.o.guifont = 'JetBrainsMono Nerd Font:h13'
        end
        require('kanagawa').setup({
          transparent = not is_neovide,
          colors = {
            theme = {
              all = {
                ui = {
                  bg_gutter = 'none',
                  float = {
                    bg = 'none',
                  }
                }
              }
            }
          },
          overrides = function(colors)
            local theme = colors.theme
            local makeDiagnosticColor = function(color)
              local c = require('kanagawa.lib.color')
              return { fg = color, bg = c(color):blend(theme.ui.bg, 0.95):to_hex() }
            end
            return {
              -------------------
              -- Floating windows
              -------------------
              NormalFloat = { bg = 'none' },
              FloatBorder = { bg = 'none' },
              FloatTitle = { bg = 'none' },
              
              -------------------
              -- Blink-cmp (Transparent & Flush)
              -------------------
              -- Force the entire menu and its elements to have no background
              Pmenu = { bg = 'none' },
              PmenuSel = { bg = theme.ui.bg_p2 }, -- The selection bar
              PmenuSbar = { bg = 'none' },
              PmenuThumb = { bg = theme.ui.bg_p2 },

              BlinkCmpMenu = { bg = 'none' },
              BlinkCmpMenuBorder = { bg = 'none', fg = theme.ui.bg_p2 },
              
              -- Individual row elements
              BlinkCmpLabel = { bg = 'none', fg = theme.ui.fg },
              BlinkCmpLabelDescription = { bg = 'none', fg = theme.ui.fg_dim },
              BlinkCmpLabelDetail = { bg = 'none', fg = theme.ui.fg_dim },
              BlinkCmpKind = { bg = 'none', fg = theme.ui.fg_dim },
              BlinkCmpSource = { bg = 'none', fg = theme.ui.fg_dim },
              BlinkCmpLabelMatch = { bg = 'none', fg = theme.diag.info, bold = true },
              
              -- The selection bar inside the menu
              BlinkCmpMenuSelection = { bg = theme.ui.bg_p2, fg = theme.ui.fg },

              -- Documentation & Signature Help
              BlinkCmpDoc = { bg = 'none' },
              BlinkCmpDocBorder = { bg = 'none', fg = theme.ui.bg_p2 },
              BlinkCmpSignatureHelp = { bg = 'none' },
              BlinkCmpSignatureHelpBorder = { bg = 'none', fg = theme.ui.bg_p2 },
              -------------------
              -- LSP Progress
              -------------------
              LspProgressStatus  = { bg = 'none' },
              LspProgressClient  = { bg = 'none' },
              LspProgressTitle   = { bg = 'none' },
              LspProgressSpinner = { bg = 'none' },
              LspProgressMsg     = { bg = 'none' },
              LspProgressDone    = { bg = 'none' },
            }
          end
        })
        vim.cmd[[colorscheme kanagawa-dragon]]
  ";
    };
    vim-tmux-navigator = {
      package = pkgs.vimPlugins.vim-tmux-navigator;
      setup = "
          vim.g.tmux_navigator_no_mappings = 1
          vim.g.tmux_navigator_no_wrap = 1
          ";
    };
    undotree = {
      package = pkgs.vimPlugins.undotree;
      setup = "";
      after = ["vim-tmux-navigator"];
    };
    neogen = {
      package = pkgs.vimPlugins.neogen;
      setup = ''
        require('neogen').setup({
          enabled = true,
          snippet_engine = "luasnip",
          languages = {
            cs = {
              template = {
                annotation_convention = "xmldoc" -- This forces the XML style
              }
            }
          }
        })
      '';
    };
  };
}
