{pkgs, ...}: {
  programs.nvf.settings.vim.extraPlugins = {
    theme-plugin = {
      package = pkgs.vimPlugins.kanagawa-nvim;
      setup = "
        require('kanagawa').setup({
          transparent = true,
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
