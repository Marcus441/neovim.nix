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
