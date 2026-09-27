{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      languages.lua = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters_by_ft.lua = [ "stylua" ];
    };
  };

  flake.modules.nvf.dev =
    {
      pkgs,
      lib,
      ...
    }:
    {
      vim = {
        languages.lua = {
          lsp.enable = true;
          extensions.lazydev.enable = true;
        };

        lsp.servers.lua-language-server.cmd = lib.mkForce [
          (preferPathExe pkgs "lua-language-server" (lib.getExe pkgs.lua-language-server))
        ];

        diagnostics.nvim-lint.linters_by_ft.lua = [ "luacheck" ];

        extraPackages = [
          pkgs.luajitPackages.luacheck
          pkgs.stylua
        ];
      };
    };
}
