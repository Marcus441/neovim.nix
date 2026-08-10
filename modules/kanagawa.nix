{
  flake.modules.nvf.core = {pkgs, ...}: {
    vim.extraPlugins = {
      theme-plugin = {
        package = pkgs.vimPlugins.kanagawa-nvim;
        setup = builtins.readFile ./kanagawa-setup.lua;
      };
    };
  };
}
