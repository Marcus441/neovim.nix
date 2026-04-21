{
  vim = {
    treesitter.queries = [
      {
        type = "highlights";
        filetypes = ["cpp"];
        content = ''
          ;; extends
          (import_declaration "import" @keyword.import)
          (import_declaration name: (module_name) @module)
          (module_declaration) @keyword.import
          (module_declaration name: (module_name) @module)
          (export_declaration "export" @keyword.import)
        '';
      }
    ];
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
      typescript = {
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
