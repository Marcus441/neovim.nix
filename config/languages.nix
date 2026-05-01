{
  vim = {
    treesitter.queries = [
      {
        type = "highlights";
        filetypes = ["cpp"];
        query = ''
          ;; extends
          (import_declaration "import" @keyword.import)
          (import_declaration name: (module_name) @module)
          (module_declaration "export"? @keyword.import "module" @keyword.import)
          (module_declaration name: (module_name) @module)
          (export_declaration "export" @keyword.import)
          (global_module_fragment_declaration "module" @keyword.import)
        '';
      }
    ];
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      # Systems
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
        lsp = {
          enable = true;
          servers = [
            "typescript-language-server"
            /*
            "angular-language-server"
            */
          ];
        };
        format.type = ["prettierd"];
        extraDiagnostics = {
          enable = true;
          types = ["eslint_d"];
        };
      };
      # Dotnet
      csharp = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["roslyn-ls"];
        };
        format = {
          enable = true;
          # type = ["csharpier"];
        };
        treesitter.enable = true;
        extensions.roslyn-nvim = {
          enable = true;
          setupOpts.filewatching = "roslyn";
          setupOpts.extensions.razor.enabled = true;
        };
      };
    };
  };
}
