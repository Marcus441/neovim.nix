{
  flake.modules.nvf.gui = {
    vim.ui.noice = {
      enable = true;
      setupOpts = {
        lsp.signature.enabled = true;
        presets = {
          command_palette = true;
          bottom_search = false;
        };
      };
    };
  };
}
