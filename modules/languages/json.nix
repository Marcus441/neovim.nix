{
  flake.modules.nvf.core = {
    vim.languages.json.enable = true;
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.jsonls.enable = true;
        extraPackages = [ pkgs.vscode-langservers-extracted ];
      };
    };
}
