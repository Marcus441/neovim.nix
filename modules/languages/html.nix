{
  flake.modules.nvf.core = {
    vim = {
      languages.html = {
        enable = true;
        treesitter.autotagHtml = false;
      };

      lazy.plugins.nvim-ts-autotag = {
        package = "nvim-ts-autotag";
        setupModule = "nvim-ts-autotag";
        ft = [
          "html"
          "htmlangular"
          "javascriptreact"
          "typescriptreact"
          "xml"
        ];
      };
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers = {
          superhtml.enable = true;
          emmet_language_server.filetypes = [
            "html"
            "htmlangular"
          ];
        };

        extraPackages = [
          pkgs.emmet-language-server
          pkgs.superhtml
        ];
      };
    };
}
