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
      shortmess = "I";
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

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    mini = {
      ai.enable = true;
      icons.enable = true;
      snippets.enable = true;
      statusline.enable = true;
      surround.enable = true;
    };

    utility = {
      oil-nvim.enable = true;
      direnv.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          bigfile.enabled = true;
          # explorer/terminal/toggle replaced by fish aliases + fzf/fd/rg
          # picker and projects kept
          picker = {
            enabled = true;
            sources.zoxide = {};
            sources.projects = {
              dev = ["~/projects" "~/oss"];
              patterns = [".git" "flake.nix" "package.json" "Makefile"];
            };
          };
          gitbrowse.enabled = true;
          image.enabled = true;
          indent = {
            enabled = true;
            indent = {char = "│";};
            animate = {enabled = false;};
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
            style = "compact";
          };
          quickfile.enabled = true;
          rename.enabled = true;
          scope.enabled = true;
          statuscolumn.enabled = true;
          words.enabled = true;
        };
      };
    };

    ui = {
      borders.enable = true;
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

    notes.todo-comments.enable = true;
    comments = {
      comment-nvim.enable = true;
    };
  };
}
