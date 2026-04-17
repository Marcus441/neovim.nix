{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>tz";
      action = "<cmd>lua Snacks.zen()<cr>";
      desc = "[T]oggle [Z]en";
    }
    {
      mode = ["n"];
      key = "<leader>tD";
      action = "<cmd>lua vim.g.snacks_dim = not vim.g.snacks_dim; if vim.g.snacks_dim then Snacks.dim.enable() else Snacks.dim.disable() end<cr>";
      desc = "[T]oggle [D]im";
    }
  ];
}
