{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.nix = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.nix.lsp = {
        enable = true;
        servers = ["nixd"];
      };

      lsp.servers.nixd.cmd = lib.mkForce [
        (preferPathExe pkgs "nixd" (lib.getExe pkgs.nixd))
      ];
    };
  };
}
