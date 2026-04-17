{
  vim = {
    session = {
      nvim-session-manager = {
        enable = true;

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

        mappings = {
          deleteSession = "<leader>sd";
          loadLastSession = "<leader>slt";
          loadSession = "<leader>sl";
          saveCurrentSession = "<leader>sc";
        };
      };
    };

    mini.sessions.enable = false;
  };
}
