{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.lua = {
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
      languages.lua.lsp = {
        enable = true;
        lazydev.enable = true;
      };

      lsp.servers.lua-language-server.cmd = lib.mkForce [
        (preferPathExe pkgs "lua-language-server" (lib.getExe pkgs.lua-language-server))
      ];
    };
  };
}
