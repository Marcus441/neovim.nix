{
  vim.keymaps = [
    {
      mode = ["x"];
      key = "<leader>p";
      action = "\"_dP";
      desc = "Paste into void register";
    }
    {
      mode = ["n"];
      key = "<leader>Y";
      action = "\"+Y";
      desc = "Yank line to system clipboard";
    }
    {
      mode = ["v"];
      key = "<leader>y";
      action = "\"+y";
      desc = "Yank to system clipboard";
    }
    {
      mode = ["n"];
      key = "<leader>y";
      action = "\"+y";
      desc = "Yank to system clipboard";
    }
    {
      mode = ["v"];
      key = "<leader>d";
      action = "\"_d";
      desc = "Delete to void register";
    }
    {
      mode = ["n"];
      key = "<leader>d";
      action = "\"_d";
      desc = "Delete to void register";
    }
  ];
}
