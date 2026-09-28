{
  flake.modules.nvf.core = {
    vim.languages = {
      css.enable = true;
      scss.enable = true;
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers = {
          cssls.enable = true;
          emmet_language_server.filetypes = [ "css" ];
        };

        extraPackages = [ pkgs.vscode-langservers-extracted ];
      };
    };
}
