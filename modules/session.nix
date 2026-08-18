{
  flake.modules.nvf.dev = {
    vim.session.nvim-session-manager = {
      enable = true;
      # load-bearing: docs/decisions/theme.md#picker-blocks
      usePicker = false;
      setupOpts = {
        autosave_last_session = true;
        autoload_mode = "Disabled";
        autosave_ignore_buftypes = [
          "nofile"
          "prompt"
          "terminal"
        ];
        autosave_ignore_filetypes = [
          "gitcommit"
          "help"
          "NvimTree"
        ];
        autosave_ignore_not_normal = true;
      };
    };
  };
}
