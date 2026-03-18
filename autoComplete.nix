{pkgs, ...}: {
  programs.nvf.settings.vim = {
    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      sourcePlugins = {
        spell.enable = true;
        # emoji.enable = true;
        # "nerdfont" = {
        #   enable = true;
        #   module = "blink-nerdfont";
        #   package = pkgs.vimPlugins.blink-nerdfont-nvim;
        # };
        ripgrep.enable = true;
      };

      setupOpts = {
        keymap.preset = "default";
        cmdline.keymap.preset = "default";
        signature.enabled = true;
      };
    };
  };
}
