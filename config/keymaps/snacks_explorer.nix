{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>ee";
      action = "<cmd>lua Snacks.explorer()<cr>";
      desc = "[E]xplorer";
    }
    {
      mode = ["n"];
      key = "<leader>er";
      action = "<cmd>lua Snacks.explorer.reveal()<cr>";
      desc = "[E]xplorer [R]eveal current file";
    }
  ];
}
