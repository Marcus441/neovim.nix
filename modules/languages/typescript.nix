{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim.languages = {
      typescript = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };

      tsx = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };
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
        languages = {
          typescript = {
            lsp = {
              enable = true;
              servers = [
                "typescript-language-server"
              ];
            };
          };

          tsx = {
            lsp = {
              enable = true;
              servers = [
                "typescript-language-server"
              ];
            };
          };
        };

        lsp.servers.typescript-language-server.cmd = lib.mkForce [
          (preferPathExe pkgs "typescript-language-server" (lib.getExe pkgs.typescript-language-server))
          "--stdio"
        ];

        diagnostics.nvim-lint = {
          linters_by_ft = {
            typescript = [ "eslint_d" ];
            typescriptreact = [ "eslint_d" ];
            javascriptreact = [ "eslint_d" ];
          };

          linters.eslint_d.required_files = [
            "eslint.config.js"
            "eslint.config.mjs"
            ".eslintrc"
            ".eslintrc.json"
            ".eslintrc.js"
            ".eslintrc.yml"
          ];
        };

        extraPackages = [ pkgs.eslint_d ];
      };
    };
}
