{
  flake.modules.nvf.dev = {
    vim.ui.noice = {
      enable = true;
      setupOpts = {
        lsp.signature.enabled = true;
        presets = {
          command_palette = true;
          bottom_search = false;
        };
        views = {
          cmdline_popup.border = {
            style = "none";
            padding = [1 2];
          };
          cmdline_popupmenu.border = {
            style = "none";
            padding = [1 2];
          };
          # load-bearing: docs/decisions/theme.md#picker-blocks
          confirm.border.style = "solid";
        };
      };
    };
  };
}
