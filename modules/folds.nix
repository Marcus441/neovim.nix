{
  flake.modules.nvf.core = {
    vim.treesitter.fold = true;
    vim.options = {
      foldlevel = 99;
      fillchars = "fold: ,foldopen:,foldclose:";
    };
  };
}
