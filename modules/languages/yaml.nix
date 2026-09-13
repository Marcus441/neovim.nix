{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.yaml = {
        enable = true;
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters_by_ft."yaml.gitlab" = ["prettier"];
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.yaml.lsp.enable = true;

      lsp.servers.yaml-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "yaml-language-server" (lib.getExe pkgs.yaml-language-server))
        "--stdio"
      ];
    };
  };
}
