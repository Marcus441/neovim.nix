{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>gs";
      action = "<CMD>Git<CR>";
      desc = "Show Git status";
    }
    {
      mode = ["n"];
      key = "<leader>gg";
      action = "<CMD>lua Snacks.lazygit()<CR>";
      desc = "Lazygit";
    }
  ];
}
