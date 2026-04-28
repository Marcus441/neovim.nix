{
  vim = {
    autocomplete.blink-cmp = {
      enable = false;
      friendly-snippets.enable = true;
      setupOpts = {
        keymap = {
          preset = "default";
          "<C-d>" = ["scroll_documentation_down" "fallback"];
          "<C-u>" = ["scroll_documentation_up" "fallback"];
        };
        cmdline.keymap.preset = "default";
        signature.enabled = true;
        fuzzy.implementation = "prefer_rust_with_warning";
        sources = {
          default = ["lsp" "snippets" "path" "buffer"];
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
          };
        };
        completion = {
          keyword.range = "full";
          trigger = {
            show_on_blocked_trigger_characters = [" " "\n" "\t"];
            show_on_x_blocked_trigger_characters = ["'" "\"" "(" "{" "["];
          };
          list.selection = {
            preselect = true;
            auto_insert = false;
          };
          accept.auto_brackets.enabled = true;
          ghost_text.enabled = true;
          menu = {
            auto_show = true;
            winblend = 0;
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
          };
        };
      };
    };
  };
}
