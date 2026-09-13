{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      vimAlias = true;
      lineNumberMode = "relNumber";
      enableLuaLoader = true;
      preventJunkFiles = true;

      options = {
        tabstop = lib.mkDefault 4;
        shiftwidth = lib.mkDefault 4;
        shortmess = "IF";
        wrap = true;
        guicursor = "i:block";
        winborder = "single";
      };
    };
  };

  flake.modules.nvf.dev = {
    vim.options = {
      tabstop = 2;
      shiftwidth = 2;
      wrap = true;
    };
  };
}
