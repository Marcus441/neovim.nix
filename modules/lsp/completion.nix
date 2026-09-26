{
  flake.modules.nvf.dev = {
    vim.autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      mappings = {
        confirm = null;
        next = null;
        previous = null;
      };
      setupOpts = {
        keymap.preset = "default";
        signature.enabled = true;
        completion.documentation.auto_show = true;
      };
    };
  };
}
