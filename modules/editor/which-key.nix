{
  flake.modules.nvf.core = {
    vim = {
      binds.whichKey = {
        enable = true;
        register."<leader>t" = "Toggle";
      };

      keymaps = [
        {
          mode = [ "n" ];
          key = "<leader>?";
          action = "<cmd>lua require('which-key').show({ global = false })<cr>";
          desc = "Buffer local keymaps";
        }
      ];
    };
  };
}
