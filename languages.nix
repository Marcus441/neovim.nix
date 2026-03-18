{
  programs.nvf.settings.vim = {
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;
      assembly = {
        enable = true;
        lsp.enable = true;
      };
      bash = {
        enable = true;
        lsp.enable = true;
      };
      clang = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["clangd"];
        };
        dap.enable = true;
      };
      csharp = {
        enable = true;
        lsp = {
          enable = true;
          # servers = ["roslyn_ls"];
        };
      };
      css = {
        enable = true;
        format.enable = true;
        format.type = ["prettierd"];
      };
      html.enable = true;
      lua.enable = true;
      markdown = {
        enable = true;
        lsp.enable = true;
        extensions.markview-nvim.enable = true;
      };
      nix = {
        enable = true;
        lsp.enable = true;
      };
      python = {
        enable = true;
        format.type = ["ruff"];
        lsp.enable = true;
      };
      rust = {
        enable = true;
        lsp.enable = true;
        extensions = {crates-nvim.enable = true;};
      };
      terraform = {
        enable = true;
        lsp.enable = true;
      };
      ts = {
        enable = true;
        lsp.enable = true;
        format.type = ["prettierd"];
        extensions.ts-error-translator.enable = true;
      };
      typst = {
        enable = true;
        lsp.enable = true;
      };
    };
  };
}
