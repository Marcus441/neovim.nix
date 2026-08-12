{
  flake.modules.nvf.gui = {
    vim.visuals.fidget-nvim = {
      enable = true;
      setupOpts = {
        notification.override_vim_notify = false;
        # load-bearing: docs/decisions/theme.md#picker-blocks
        notification.window.border = "none";
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
}
