{
  flake.modules.nvf.dev = {
    vim.binds.whichKey.register."<leader>q" = "Session";

    vim.session.nvim-session-manager = {
      enable = true;
      usePicker = false;
      mappings = {
        loadSession = "<leader>qs";
        loadLastSession = "<leader>ql";
        saveCurrentSession = "<leader>qw";
        deleteSession = "<leader>qd";
      };
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
