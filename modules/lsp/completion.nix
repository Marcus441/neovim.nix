{
  flake.modules.nvf.dev = { lib, ... }: {
    vim.lsp.servers."*".capabilities = lib.mkLuaInline ''
      require("blink.cmp").get_lsp_capabilities()
    '';

    vim.autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      setupOpts = {
        keymap.preset = "enter";
        signature.enabled = true;
        sources.providers = {
          lsp = {
            score_offset = 5;
            fallbacks = [ ];
          };
          snippets.score_offset = 4;
          path.score_offset = 3;
          buffer = {
            score_offset = 2;
            max_items = 5;
          };
        };
        completion = {
          documentation.auto_show = true;
          list.selection = {
            preselect = true;
            auto_insert = false;
          };
        };
      };
    };
  };
}
