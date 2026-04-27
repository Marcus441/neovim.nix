{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>gs";
      action = "<CMD>Git<CR>";
      desc = "Show [G]it [S]tatus";
    }
    {
      mode = ["n"];
      key = "<leader>gb";
      action = "<cmd>lua Snacks.gitbrowse()<cr>";
      desc = "[G]it [B]rowse";
    }
    {
      mode = ["n"];
      key = "<leader>L";
      action = "<cmd>lua Snacks.lazygit()<cr>";
      desc = "[L]azygit";
    }
  ];
}
