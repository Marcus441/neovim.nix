{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.rust = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.rust = {
        lsp.enable = true;
        extensions.crates-nvim.enable = true;
      };

      # load-bearing: docs/decisions/prefer-path.md#rustaceanvim-owns-activation
      lsp.servers.rust-analyzer = {
        enable = false;
        cmd = lib.mkForce [
          (preferPathExe pkgs "rust-analyzer" (lib.getExe pkgs.rust-analyzer))
        ];
        # load-bearing: docs/decisions/prefer-path.md#rustaceanvim-owns-activation
        filetypes = ["rust"];
      };
    };
  };
}
