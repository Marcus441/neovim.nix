{
  flake.modules.nvf.core = {
    vim = {
      languages.lua.enable = true;
      formatter.conform-nvim.setupOpts.formatters_by_ft.lua = [ "stylua" ];
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        languages.lua.extensions.lazydev.enable = true;
        lsp.servers.lua_ls.enable = true;

        extraPackages = [
          pkgs.lua-language-server
          pkgs.stylua
        ];
      };
    };
}
