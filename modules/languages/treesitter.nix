{
  flake.modules.nvf.core = {
    vim = {
      languages.enableTreesitter = true;

      treesitter = {
        enable = true;
        indent.enable = true;
      };
    };
  };
}
