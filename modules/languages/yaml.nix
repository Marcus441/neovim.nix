{
  flake.modules.nvf.core = {
    vim.languages.yaml.enable = true;
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.yamlls.enable = true;
        extraPackages = [ pkgs.yaml-language-server ];
      };
    };
}
