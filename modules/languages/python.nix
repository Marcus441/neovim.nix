{
  flake.modules.nvf.core = {
    vim = {
      languages.python.enable = true;
      formatter.conform-nvim.setupOpts.formatters_by_ft.python = [ "ruff_format" ];
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.basedpyright.enable = true;

        extraPackages = [
          pkgs.basedpyright
          pkgs.ruff
        ];
      };
    };
}
