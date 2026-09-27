{
  flake.modules.nvf.core = {
    vim.languages.html.enable = true;
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.superhtml.enable = true;
        extraPackages = [ pkgs.superhtml ];
      };
    };
}
