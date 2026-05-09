{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<C-=>";
      action = "function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end";
      lua = true;
      desc = "Increase window scale";
    }
    {
      mode = ["n"];
      key = "<C-->";
      action = "function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end";
      lua = true;
      desc = "Decrease window scale";
    }
  ];
}
