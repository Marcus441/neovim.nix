{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>tt";
      action = "<cmd>lua Snacks.terminal()<cr>";
      desc = "[T]oggle [T]erminal";
    }
    {
      mode = ["n"];
      key = "<leader>tl";
      action = "<cmd>lua Snacks.lazygit()<cr>";
      desc = "[T]oggle [L]azygit";
    }
  ];
}
