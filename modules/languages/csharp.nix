{
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.csharp = {
      enable = true;
      treesitter.enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    vim.languages.csharp = {
      lsp = {
        enable = true;
        servers = ["roslyn-ls"];
      };
      format.enable = true;
      extensions.roslyn-nvim = {
        enable = true;
        setupOpts.filewatching = "roslyn";
        setupOpts.extensions.razor.enabled = true;
      };
    };
  };
}
