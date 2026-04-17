{
  config.vim = {
    vimAlias = true;
    undoFile.enable = true;
    lineNumberMode = "relNumber";
    enableLuaLoader = true;
    preventJunkFiles = true;
    treesitter = {
      indent.enable = true;
    };
    options = {
      tabstop = 2;
      shiftwidth = 2;
      wrap = true;
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

    spellcheck = {
      enable = true;
      languages = ["en"];
      programmingWordlist.enable = true;
    };

    visuals = {
      nvim-web-devicons.enable = true;
      nvim-cursorline.enable = true;
      highlight-undo.enable = true;
    };

    autopairs.nvim-autopairs.enable = true;

    binds = {
      whichKey = {
        enable = true;
        register = {
          "<leader>c" = "[C]ode";
          "<leader>d" = "[D]ocument";
          "<leader>r" = "[R]ename";
          "<leader>s" = "[S]earch";
          "<leader>w" = "[W]orkspace";
          "<leader>t" = "[T]oggle";
          "<leader>h" = "Git [H]unk";
        };
      };
    };

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    statusline.lualine.enable = true;

    mini = {
      icons.enable = true;
      ai.enable = true;
      snippets.enable = true;
      surround.enable = true;
    };

    utility = {
      diffview-nvim.enable = true;
      direnv.enable = true;
      icon-picker.enable = true;
      oil-nvim.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          bigfile.enabled = true;
          dim.enabled = true;
          explorer = {
            enabled = true;
            replace_netrw = true;
          };
          gitbrowse.enabled = true;
          image.enabled = true;
          indent = {
            enabled = true;
            indent = {char = "│";};
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
          input.enabled = true;
          lazygit = {enabled = true;};
          notifier = {
            enabled = true;
            timeout = 3000;
            style = "fancy";
          };
          picker = {
            enabled = true;
            sources.zoxide = {};
            sources.projects = {
              dev = ["~/projects" "~/oss"];
              patterns = [".git" "flake.nix" "package.json" "Makefile"];
            };
          };
          quickfile.enabled = true;
          rename.enabled = true;
          scope.enabled = true;
          scratch.enabled = true;
          statuscolumn.enabled = true;
          terminal = {enabled = true;};
          toggle.enabled = true;
          words.enabled = true;
          zen.enabled = true;
        };
      };
    };

    ui = {
      borders.enable = true;
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

      smartcolumn = {
        enable = true;
        setupOpts.disabled_filetypes = [
          "help"
          "text"
          "markdown"
          "NvimTree"
          "alpha"
          "snacks_dashboard"
        ];
      };
      fastaction.enable = true;
    };

    notes.todo-comments.enable = true;
    comments = {
      comment-nvim.enable = true;
    };
  };
}
