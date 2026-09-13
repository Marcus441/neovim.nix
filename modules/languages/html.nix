{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.html = {
      enable = true;
      format.type = ["prettier"];
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.html = {
        lsp.enable = true;
        extraDiagnostics.enable = false;
      };

      lsp.servers.superhtml.cmd = lib.mkForce [
        (preferPathExe pkgs "superhtml" (lib.getExe pkgs.superhtml))
        "lsp"
      ];
    };
  };
}
