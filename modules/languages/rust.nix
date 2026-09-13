{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.rust = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters.rustfmt.command = lib.mkForce "rustfmt";
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.rust = {
        lsp.enable = true;
        extensions.crates-nvim.enable = true;
      };

      lsp.servers.rust-analyzer = {
        enable = lib.mkForce false;
        cmd = lib.mkForce [
          (preferPathExe pkgs "rust-analyzer" (lib.getExe pkgs.rust-analyzer))
        ];
        filetypes = ["rust"];
      };
    };
  };
}
