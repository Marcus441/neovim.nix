{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "J";
      action = "mzJ`z";
      desc = "Join line and keep cursor position";
    }
    {
      mode = ["n"];
      key = "<C-d>";
      action = "<C-d>zz";
      desc = "Half page down and center";
    }
    {
      mode = ["n"];
      key = "<C-u>";
      action = "<C-u>zz";
      desc = "Half page up and center";
    }
    {
      mode = ["n"];
      key = "n";
      action = "nzzzv";
      desc = "Next search match and center";
    }
    {
      mode = ["n"];
      key = "N";
      action = "Nzzzv";
      desc = "Previous search match and center";
    }
    {
      mode = ["v"];
      key = "J";
      action = ":m '>+1<CR>gv=gv";
      desc = "Move visual block down";
    }
    {
      mode = ["v"];
      key = "K";
      action = ":m '<-2<CR>gv=gv";
      desc = "Move visual block up";
    }
  ];
}
