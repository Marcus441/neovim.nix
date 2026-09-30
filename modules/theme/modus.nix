{ lib, ... }: {
  flake.modules.nvf.core = { pkgs, ... }: {
    vim.globals.theme_transparent = lib.mkDefault true;

    vim.extraPlugins = {
      theme-plugin = {
        package = pkgs.vimPlugins.modus-themes-nvim;
        setup = builtins.readFile ./modus.lua;
      };
    };
  };

  flake.modules.nvf.neovide.vim.globals.theme_transparent = false;
}
