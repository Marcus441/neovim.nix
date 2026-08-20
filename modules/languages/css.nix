{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages = {
      css = {
        enable = true;
        # load-bearing: docs/decisions/data-languages.md#prettier-everywhere
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;
      };

      scss = {
        enable = true;
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;
      };
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages = {
        css.lsp.enable = true;

        scss = {
          lsp = {
            enable = true;
            # load-bearing: docs/decisions/data-languages.md#scss-declines-some-sass
            servers = ["vscode-css-language-server"];
          };
          # load-bearing: docs/decisions/data-languages.md#the-linters-stay-off
          extraDiagnostics.enable = false;
        };
      };

      lsp.servers.vscode-css-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "vscode-css-language-server"
          (lib.getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server"))
        "--stdio"
      ];
    };
  };
}
