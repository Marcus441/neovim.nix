{
  vim.languages = {
    enableExtraDiagnostics = true;

    clang = {
      lsp = {
        enable = true;
        servers = ["clangd"];
      };
      dap.enable = true;
    };
    rust = {
      lsp.enable = true;
      extensions.crates-nvim.enable = true;
    };
    lua.lsp = {
      enable = true;
      lazydev.enable = true;
    };
    nix.lsp.enable = true;
    python.lsp.enable = true;
    typescript = {
      lsp = {
        enable = true;
        servers = [
          "typescript-language-server"
          /*
          "angular-language-server"
          */
        ];
      };
      extraDiagnostics = {
        enable = true;
        types = ["eslint_d"];
      };
    };
    csharp = {
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
