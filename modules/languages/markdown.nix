{
  flake.modules.nvf.core = {
    vim = {
      languages.markdown = {
        enable = true;

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
          mode = [ "n" ];
          key = "<leader>tm";
          action = "<CMD>RenderMarkdown toggle<CR>";
          desc = "[T]oggle [M]arkdown rendering";
        }
      ];
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        utility.preview.markdownPreview.enable = true;
        lsp.servers.marksman.enable = true;
        diagnostics.nvim-lint.linters_by_ft.markdown = [ "markdownlint-cli2" ];

        extraPackages = [
          pkgs.markdownlint-cli2
          pkgs.marksman
          pkgs.nodejs
        ];

        keymaps = [
          {
            mode = [ "n" ];
            key = "<leader>mp";
            action = "<CMD>MarkdownPreviewToggle<CR>";
            desc = "[M]arkdown [P]review";
          }
        ];
      };
    };
}
