{
  flake.modules.nvf.dev =
    { lib, ... }:
    {
      vim = {
        utility.snacks-nvim.setupOpts.indent.enabled = true;

        luaConfigRC.toggle-indent = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
          Snacks.toggle.indent():map("<leader>ti")
        '';
      };
    };
}
