{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      vimAlias = true;
      lineNumberMode = "relNumber";
      enableLuaLoader = true;
      preventJunkFiles = true;

      options = {
        tabstop = lib.mkDefault 4;
        shiftwidth = lib.mkDefault 4;
        shortmess = "IF";
        wrap = false;
        linebreak = true;
        breakindent = true;
        sidescrolloff = 8;
        guicursor = "i:block";
        winborder = "single";
      };

      luaConfigRC.toggle-wrap = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
        Snacks.toggle.option("wrap", { name = "Line wrap" }):map("<leader>tl")
      '';
    };
  };

  flake.modules.nvf.dev = {
    vim.options = {
      tabstop = 2;
      shiftwidth = 2;
    };
  };
}
