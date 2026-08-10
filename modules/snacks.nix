{
  flake.modules.nvf.core = {
    vim.utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        bigfile.enabled = true;
        input.enabled = true;
        quickfile.enabled = true;
        scope.enabled = true;
        statuscolumn.enabled = true;
      };
    };
  };

  flake.modules.nvf.gui = {
    vim.utility.snacks-nvim.setupOpts = {
      dim.enabled = true;
      rename.enabled = true;
      words.enabled = true;
    };
  };
}
