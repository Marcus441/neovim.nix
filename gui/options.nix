{
  config.vim = {
    options = {
      tabstop = 2;
      shiftwidth = 2;
      wrap = true;
    };

    spellcheck = {
      enable = true;
      languages = ["en"];
      programmingWordlist.enable = true;
    };

    visuals.nvim-cursorline.enable = true;
    autopairs.nvim-autopairs.enable = true;
    notes.todo-comments.enable = true;

    utility.snacks-nvim.setupOpts = {
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
}
