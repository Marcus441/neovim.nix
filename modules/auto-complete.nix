{
  flake.modules.nvf.dev = {
    vim = {
      autocomplete.blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        # load-bearing: docs/decisions/completion-keymaps.md#nulling-nvfs-mappings
        mappings = {
          confirm = null;
          next = null;
          previous = null;
        };
        setupOpts = {
          keymap.preset = "default";
          cmdline.keymap = {
            preset = "default";
            "<Tab>" = ["select_next" "show" "fallback"];
            "<S-Tab>" = ["select_prev" "fallback"];
          };
          signature = {
            enabled = true;
            window = {
              border = "solid";
              winblend = 0;
            };
          };
          fuzzy.implementation = "prefer_rust_with_warning";
          sources = {
            default = ["lsp" "snippets" "path" "buffer"];
            per_filetype = {
              sql = ["dadbod" "lsp" "snippets" "buffer"];
            };
            providers = {
              lsp = {
                score_offset = 5;
                fallbacks = [];
              };
              snippets = {
                score_offset = 4;
              };
              path = {
                score_offset = 3;
              };
              buffer = {
                score_offset = 2;
                max_items = 5;
              };
              dadbod = {
                name = "Dadbod";
                module = "vim_dadbod_completion.blink";
                score_offset = 30;
              };
            };
          };
          completion = {
            keyword.range = "full";
            trigger = {
              show_on_blocked_trigger_characters = [" " "\n" "\t"];
              show_on_x_blocked_trigger_characters = ["'" "\"" "(" "{" "["];
            };
            list.selection = {
              preselect = false;
              auto_insert = false;
            };
            accept.auto_brackets.enabled = true;
            ghost_text = {
              enabled = true;
              show_without_selection = true;
            };
            menu = {
              auto_show = true;
              winblend = 0;
              border = "solid";
              draw = {
                treesitter = ["lsp"];
                columns = [
                  ["kind_icon"]
                  ["label" "label_description"]
                  ["source_name"]
                ];
                gap = 1;
              };
            };
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 300;
              window = {
                border = "solid";
                winblend = 0;
              };
            };
          };
        };
      };
    };
  };
}
