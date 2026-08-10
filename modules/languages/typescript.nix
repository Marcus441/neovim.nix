{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.typescript = {
      enable = true;
      format.type = ["prettier"];
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.typescript = {
        lsp = {
          enable = true;
          servers = [
            "typescript-language-server"
          ];
        };
        extraDiagnostics = {
          enable = true;
          types = ["eslint_d"];
        };
      };

      lsp.servers.typescript-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "typescript-language-server" (lib.getExe pkgs.typescript-language-server))
        "--stdio"
      ];

      diagnostics.nvim-lint.linters.eslint_d.cmd =
        lib.mkForce
        (preferPathExe pkgs "eslint_d" (lib.getExe pkgs.eslint_d));
    };
  };
}
