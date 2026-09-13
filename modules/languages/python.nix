{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.python = {
        enable = true;
        format.type = ["ruff"];
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters.ruff.command = lib.mkForce "ruff";
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.python.lsp.enable = true;

      lsp.servers.basedpyright.cmd = lib.mkForce [
        (preferPathExe pkgs "basedpyright-langserver" (lib.getExe' pkgs.basedpyright "basedpyright-langserver"))
        "--stdio"
      ];

      formatter.conform-nvim.setupOpts.formatters.ruff.command =
        lib.mkOverride 40
        (preferPathExe pkgs "ruff" (lib.getExe pkgs.ruff));
    };
  };
}
