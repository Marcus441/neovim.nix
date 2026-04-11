{pkgs, ...}: {
  vim = {
    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      sourcePlugins = {
        spell.enable = true;
        ripgrep.enable = true;
      };

      setupOpts = {
        keymap.preset = "default";
        cmdline.keymap.preset = "default";
        signature.enabled = true;
        sources = {
          default = ["lsp" "snippets" "path" "buffer" "ripgrep" "spell"];

          providers = {
            lsp = {
              name = "LSP";
              module = "blink.cmp.sources.lsp";
              score_offset = 100;
            };
            snippets = {score_offset = 80;};
            path = {score_offset = 50;};
            buffer = {score_offset = 20;};
            ripgrep = {
              score_offset = 10;
              min_keyword_length = 4;
            };
            spell = {score_offset = 5;};
          };
        };
        completion = {
          ghost_text.enabled = true;

          menu = {
            border = "rounded";
            winblend = 0;
            draw = {
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
            window.border = "rounded";
          };
        };
      };
    };
  };
}
