{
  flake.modules.nvf.core = {
    vim = {
      mini.surround.enable = true;
      binds.whichKey.register."s" = "Surround";
    };
  };
}
