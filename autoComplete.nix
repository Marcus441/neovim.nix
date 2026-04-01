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
