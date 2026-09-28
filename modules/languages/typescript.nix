{
  flake.modules.nvf.core = {
    vim.languages = {
      typescript.enable = true;
      tsx.enable = true;
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers = {
          ts_ls.enable = true;
          emmet_language_server.filetypes = [ "typescriptreact" ];
        };

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

        extraPackages = [
          pkgs.eslint_d
          pkgs.typescript-language-server
        ];
      };
    };
}
