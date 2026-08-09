{
  flake.modules.nvf.core = {lib, ...}: {
    config.vim = {
      vimAlias = true;
      undoFile.enable = true;
      lineNumberMode = "relNumber";
      enableLuaLoader = true;
      preventJunkFiles = true;
      treesitter = {
        enable = true;
        indent.enable = true;
      };
      options = {
        tabstop = lib.mkDefault 4;
        shiftwidth = lib.mkDefault 4;
        shortmess = "IF";
        wrap = true;
        guicursor = "i:block";
        winborder = "single";
      };

      clipboard = {
        enable = true;
        registers = "unnamedplus";
        providers = {
          wl-copy.enable = true;
          xsel.enable = true;
        };
      };

      diagnostics = {
        enable = true;
        config = {
          underline = true;
          severity_sort = true;
          signs = true;
          virtual_lines = {
            current_line = true;
            severity = {
              min = "INFO";
            };
          };
          virtual_text = {
            current_line = false;
            severity = {
              min = "INFO";
            };
            spacing = 4;
            prefix = "●";
            source = "if_many";
          };
        };
      };

      visuals = {
        nvim-web-devicons.enable = true;
        highlight-undo.enable = true;
      };

      git = {
        enable = true;
        gitsigns.enable = true;
      };

      mini = {
        ai.enable = true;
        icons.enable = true;
        statusline.enable = lib.mkDefault true;
        surround.enable = true;
      };

      utility = {
        oil-nvim.enable = true;
        snacks-nvim = {
          enable = true;
          setupOpts = {
            bigfile.enabled = true;
            picker = {
              enabled = true;
              sources.zoxide = {};
              sources.projects = {
                dev = ["~/Projects" "~/projects" "~/oss"];
                patterns = [".git" "flake.nix" "package.json" "Makefile"];
              };
            };
            input.enabled = true;
            quickfile.enabled = true;
            scope.enabled = true;
            statuscolumn.enabled = true;
          };
        };
      };

      ui = {
        borders = {
          enable = true;
          globalStyle = "single";
        };
      };

      comments = {
        comment-nvim.enable = true;
      };
    };
  };

  flake.modules.nvf.gui = {
    config.vim = {
      options = {
        tabstop = 2;
        shiftwidth = 2;
        wrap = true;
      };

      spellcheck = {
        enable = true;
        languages = ["en"];
        programmingWordlist.enable = false;
      };

      visuals = {
        nvim-cursorline.enable = true;
        fidget-nvim = {
          enable = true;
          setupOpts = {
            notification.override_vim_notify = false;
            progress = {
              suppress_on_insert = true;
              ignore_done_already = true;
              ignore_empty_message = true;
              display = {
                done_ttl = 2;
                progress_icon.pattern = "dots";
              };
            };
          };
        };
      };

      autopairs.nvim-autopairs.enable = true;
      notes.todo-comments.enable = true;

      utility = {
        direnv.enable = true;
        snacks-nvim.setupOpts = {
          dim.enabled = true;
          gitbrowse.enabled = true;
          indent = {
            enabled = true;
            indent.char = "│";
            scope = {
              enabled = true;
              char = "┃";
            };
            chunk = {
              enabled = true;
              char = {
                corner_top = "╭";
                corner_bottom = "╰";
                horizontal = "─";
                vertical = "│";
                arrow = "─";
              };
            };
          };
          lazygit.enabled = true;
          notifier = {
            enabled = true;
            timeout = 3000;
            style = "fancy";
          };
          rename.enabled = true;
          scratch.enabled = true;
          words.enabled = true;
          zen.enabled = true;
        };
      };
      ui = {
        noice.enable = true;
        noice.setupOpts = {
          lsp.signature.enabled = true;
          presets = {
            command_palette = true;
            bottom_search = false;
          };
        };
        colorizer = {
          enable = true;
          setupOpts = {
            filetypes = {
              "*" = {
                RGB = true;
                RRGGBB = true;
                always_update = true;
                css = true;
                mode = "background";
              };
            };
          };
        };
      };
    };
  };
}
