{
  vim = {
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      # Systems
      assembly = {
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
      rust = {
        enable = true;
        lsp.enable = true;
        extensions = {crates-nvim.enable = true;};
      };

      # Scripting
      bash = {
        enable = true;
        lsp.enable = true;
      };
      lua = {
        enable = true;
        lsp = {
          enable = true;
          lazydev.enable = true;
        };
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

      # Web
      ts = {
        enable = true;
        lsp.enable = true;
        format.type = ["prettierd"];
        extensions.ts-error-translator.enable = true;
      };

      # Prose
      markdown = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["marksman"];
        };
        format = {
          enable = true;
          type = ["rumdl"];
        };
        extraDiagnostics = {
          enable = true;
          types = ["rumdl"];
        };
        extensions.markview-nvim.enable = true;
      };
    };
  };
}
