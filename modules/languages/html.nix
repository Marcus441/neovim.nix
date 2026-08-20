{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.html = {
      enable = true;
      # load-bearing: docs/decisions/data-languages.md#html-uses-superhtml-for-lsp-only
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
        # load-bearing: docs/decisions/data-languages.md#the-linters-stay-off
        extraDiagnostics.enable = false;
      };

      lsp.servers.superhtml.cmd = lib.mkForce [
        (preferPathExe pkgs "superhtml" (lib.getExe pkgs.superhtml))
        "lsp"
      ];
    };
  };
}
