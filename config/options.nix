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
      tabstop = 4;
      shiftwidth = 4;
      shortmess = "I";
      wrap = false;
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
      nvim-cursorline.enable = false;
      highlight-undo.enable = true;
    };

    git = {
      enable = true;
      gitsigns.enable = true;
    };

    mini = {
      ai.enable = true;
      icons.enable = true;
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
}
