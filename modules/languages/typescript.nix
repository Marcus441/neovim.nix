{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages = {
      typescript = {
        enable = true;
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;
      };

      tsx = {
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
        typescript = {
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

        tsx = {
          lsp = {
            enable = true;
            servers = [
              "typescript-language-server"
            ];
          };
          # load-bearing: docs/decisions/typescript.md#tsx-declines-biome-and-keeps-eslint_d
          extraDiagnostics.enable = false;
        };
      };

      lsp.servers.typescript-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "typescript-language-server" (lib.getExe pkgs.typescript-language-server))
        "--stdio"
      ];

      diagnostics.nvim-lint = {
        # load-bearing: docs/decisions/typescript.md#tsx-declines-biome-and-keeps-eslint_d
        linters_by_ft = {
          typescriptreact = ["eslint_d"];
          javascriptreact = ["eslint_d"];
        };

        linters.eslint_d.cmd =
          lib.mkForce
          (preferPathExe pkgs "eslint_d" (lib.getExe pkgs.eslint_d));
      };
    };
  };
}
