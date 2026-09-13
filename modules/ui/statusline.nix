{
  flake.modules.nvf.core = {lib, ...}: {
    vim.mini.statusline.enable = lib.mkDefault true;
  };

  flake.modules.nvf.dev = {
    vim = {
      mini.statusline.enable = false;
      statusline.lualine = {
        enable = true;
        theme = "auto";
      };
    };
  };
}
