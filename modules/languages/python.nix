{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.python = {
      enable = true;
      format.type = ["ruff"];
      lsp.enable = lib.mkDefault false;
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
    };
  };
}
