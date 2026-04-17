{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>T";
      action = "<cmd>lua Snacks.terminal()<cr>";
      desc = "[T]erminal";
    }
    {
      mode = ["n"];
      key = "<leader>L";
      action = "<cmd>lua Snacks.lazygit()<cr>";
      desc = "[L]azygit";
    }
  ];
}
