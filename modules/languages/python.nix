{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      languages.python = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters_by_ft.python = [ "ruff_format" ];
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
        languages.python.lsp.enable = true;

        lsp.servers.basedpyright.cmd = lib.mkForce [
          (preferPathExe pkgs "basedpyright-langserver" (
            lib.getExe' pkgs.basedpyright "basedpyright-langserver"
          ))
          "--stdio"
        ];

        extraPackages = [ pkgs.ruff ];
      };
    };
}
