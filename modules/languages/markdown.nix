{
  flake.modules.nvf.core = { lib, ... }: {
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

      luaConfigRC.toggle-markdown = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
        Snacks.toggle({
          name = "Markdown rendering",
          get = require("render-markdown").get,
          set = require("render-markdown").set,
        }):map("<leader>tm")
      '';
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
            key = "<leader>tp";
            action = "<CMD>MarkdownPreviewToggle<CR>";
            desc = "[T]oggle markdown [P]review";
          }
        ];
      };
    };
}
