{
  config.vim = {
    vimAlias = true;
    undoFile.enable = true;
    lineNumberMode = "relNumber";
    enableLuaLoader = true;
    preventJunkFiles = true;
    treesitter = {
      context.enable = false;
      indent.enable = false;
    };
    options = {
      tabstop = 4;
      shiftwidth = 2;
      smartindent = true;
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
        update_in_insert = false;
        underline = true;
        severity_sort = true;
        signs = true;
        virtual_lines = {
          current_line = true;
          severity = {
            min = "ERROR";
          };
        };
        virtual_text = {
          severity = {
            min = "INFO";
            max = "WARN";
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
      cinnamon-nvim.enable = false; # replaced by snacks.scroll
      fidget-nvim.enable = false; # replaced by snacks.notifier
      highlight-undo.enable = true;
      indent-blankline.enable = false; # replaced by snacks.indent
    };

    autopairs.nvim-autopairs.enable = true;

    snippets = {
      luasnip.enable = true;
      luasnip.loaders = "require('luasnip.loaders.from_vscode').lazy_load()";
    };

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
      cheatsheet.enable = true;
    };

    git = {
      enable = true;
      gitsigns.enable = true;
      gitsigns.codeActions.enable = false;
    };

    projects.project-nvim.enable = false; # replaced by snacks.picker.projects

    statusline.lualine.enable = true;
    mini = {
      icons.enable = true;
      ai.enable = true;
      snippets.enable = true;
      surround.enable = true;
      indentscope.enable = false; # replaced by snacks.indent
    };

    utility = {
      ccc.enable = false;
      diffview-nvim.enable = true;
      direnv.enable = true;
      icon-picker.enable = true;
      motion = {precognition.enable = false;};
      oil-nvim.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          image.enabled = true;
          bigfile.enabled = true;
          quickfile.enabled = true;
          scroll.enabled = true;
          words.enabled = true;
          input.enabled = true;
          statuscolumn.enabled = true;
          indent = {
            enabled = true;
            indent = {
              char = "│";
            };
            scope = {
              enabled = true;
              char = "┃";
            };
          };
          notifier = {
            enabled = true;
            timeout = 3000;
            style = "fancy";
          };
          picker = {
            enabled = true;
          };
          terminal = {
            enabled = true;
          };
          lazygit = {
            enabled = true;
          };
        };
      };
      surround.enable = true;
      vim-wakatime.enable = false;
    };

    ui = {
      borders.enable = true;
      noice = {
        enable = true;
        setupOpts.lsp.signature.enabled = true;
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

      illuminate.enable = true;
      breadcrumbs = {
        enable = false;
        navbuddy.enable = false;
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
