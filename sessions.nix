{
  programs.nvf.settings.vim = {
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
          deleteSession = "<leader>sd"; # Delete session
          loadLastSession = "<leader>slt"; # Load last session
          loadSession = "<leader>sl"; # Pick and load session
          saveCurrentSession = "<leader>sc"; # Save current session
        };
      };
    };

    mini.sessions.enable = false;
  };
}
