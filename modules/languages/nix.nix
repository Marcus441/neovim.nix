{
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.nix = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    vim.languages.nix.lsp = {
      enable = true;
      servers = ["nixd"];
    };
  };
}
