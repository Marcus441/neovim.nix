{pkgs, ...}: {
  vim.extraPlugins = {
    theme-plugin = {
      package = pkgs.vimPlugins.kanagawa-nvim;
      setup = builtins.readFile ./lua/kanagawa-setup.lua;
    };
    undotree = {
      package = pkgs.vimPlugins.undotree;
      after = ["theme-plugin"];
    };
  };
}
