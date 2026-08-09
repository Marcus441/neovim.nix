{
  flake.modules.nvf.gui = {
    vim = {
      mini.statusline.enable = false;
      statusline.lualine = {
        enable = true;
        theme = "auto";
      };
    };
  };
}
