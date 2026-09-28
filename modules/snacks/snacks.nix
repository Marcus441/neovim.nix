{
  flake.modules.nvf.core = {
    vim.utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        bigfile.enabled = true;
        input.enabled = true;
        quickfile.enabled = true;
        scope.enabled = true;
      };
    };
  };

  flake.modules.nvf.dev =
    { lib, ... }:
    {
      vim = {
        utility.snacks-nvim.setupOpts = {
          dim.enabled = true;
          rename.enabled = true;
          words.enabled = true;
        };

        luaConfigRC.toggle-snacks = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
          Snacks.toggle.dim():map("<leader>tD")
          Snacks.toggle.words():map("<leader>tw")
        '';
      };
    };
}
