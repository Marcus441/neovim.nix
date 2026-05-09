{lib, ...}: {
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
      enableExtraDiagnostics = lib.mkDefault false;

      clang = {
        enable = true;
        lsp.enable = lib.mkDefault false;
        dap.enable = lib.mkDefault false;
      };
      rust = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };
      lua = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };
      nix = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };
      python = {
        enable = true;
        format.type = ["ruff"];
        lsp.enable = lib.mkDefault false;
      };
      typescript = {
        enable = true;
        format.type = ["prettierd"];
        lsp.enable = lib.mkDefault false;
      };
      csharp = {
        enable = true;
        treesitter.enable = true;
        lsp.enable = lib.mkDefault false;
      };
    };
  };
}
