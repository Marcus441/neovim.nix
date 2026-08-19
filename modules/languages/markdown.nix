{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.markdown = {
        enable = true;
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;

        extensions.render-markdown-nvim = {
          enable = true;
          setupOpts = {
            # load-bearing: docs/decisions/markdown.md#latex-rendering-is-disabled
            latex.enabled = false;
            sign.enabled = false;
          };
        };
      };

      keymaps = [
        {
          mode = ["n"];
          key = "<leader>tm";
          action = "<CMD>RenderMarkdown toggle<CR>";
          desc = "[T]oggle [M]arkdown rendering";
        }
      ];
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.markdown = {
        lsp = {
          enable = true;
          servers = ["marksman"];
        };
        extraDiagnostics = {
          enable = true;
          types = ["markdownlint-cli2"];
        };
      };

      lsp.servers.marksman.cmd = lib.mkForce [
        (preferPathExe pkgs "marksman" (lib.getExe pkgs.marksman))
        "server"
      ];

      diagnostics.nvim-lint.linters.markdownlint-cli2.cmd =
        lib.mkForce
        (preferPathExe pkgs "markdownlint-cli2" (lib.getExe pkgs.markdownlint-cli2));
    };
  };
}
