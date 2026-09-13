{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
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
      utility.preview.markdownPreview.enable = true;
      extraPackages = [pkgs.nodejs];

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

      keymaps = [
        {
          mode = ["n"];
          key = "<leader>mp";
          action = "<CMD>MarkdownPreviewToggle<CR>";
          desc = "[M]arkdown [P]review";
        }
      ];
    };
  };
}
