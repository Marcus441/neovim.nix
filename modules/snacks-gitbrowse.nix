{
  flake.modules.nvf.dev = {
    vim.utility.snacks-nvim.setupOpts.gitbrowse.enabled = true;

    vim.keymaps = [
      {
        mode = ["n"];
        key = "<leader>gb";
        action = "<cmd>lua Snacks.gitbrowse()<cr>";
        desc = "[G]it [B]rowse";
      }
    ];
  };
}
