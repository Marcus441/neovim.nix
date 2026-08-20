{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.yaml = {
        enable = true;
        # load-bearing: docs/decisions/data-languages.md#prettier-everywhere
        format.type = ["prettier"];
        lsp.enable = lib.mkDefault false;
      };

      # load-bearing: docs/decisions/data-languages.md#templates-yaml-becomes-a-gitlab-filetype
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
