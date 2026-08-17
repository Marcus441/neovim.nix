{
  flake.modules.nvf.core = {
    vim.options = {
      cursorline = true;
      cursorlineopt = "number";
    };
  };

  flake.modules.nvf.gui = {
    vim.visuals.nvim-cursorline.enable = true;
  };
}
