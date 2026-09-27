{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim.languages.html = {
      enable = true;
      lsp.enable = lib.mkDefault false;
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
        languages.html.lsp.enable = true;

        lsp.servers.superhtml.cmd = lib.mkForce [
          (preferPathExe pkgs "superhtml" (lib.getExe pkgs.superhtml))
          "lsp"
        ];
      };
    };
}
