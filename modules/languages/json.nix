{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.json = {
      enable = true;
      format.type = ["prettier"];
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.json.lsp.enable = true;

      lsp.servers.vscode-json-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "vscode-json-language-server"
          (lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server"))
        "--stdio"
      ];
    };
  };
}
