{lib, ...}: {
  flake.modules.nvf.core = {pkgs, ...}: {
    vim.globals.theme_transparent = lib.mkDefault true;

    vim.extraPlugins = {
      theme-plugin = {
        package = pkgs.vimPlugins.kanagawa-nvim;
        setup = builtins.readFile ./kanagawa-setup.lua;
      };
    };
  };

  flake.modules.nvf.dev.vim.globals.theme_transparent = false;
}
