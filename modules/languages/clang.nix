{
  flake.modules.nvf.core = {
    vim = {
      treesitter.queries = [
        {
          type = "highlights";
          loadtype = "extends";
          filetypes = [ "cpp" ];
          query = ''
            (import_declaration "import" @keyword.import)
            (import_declaration name: (module_name) @module)
            (module_declaration "export"? @keyword.import "module" @keyword.import)
            (module_declaration name: (module_name) @module)
            (export_declaration "export" @keyword.import)
            (global_module_fragment_declaration "module" @keyword.import)
          '';
        }
      ];
      formatter.conform-nvim.setupOpts.formatters_by_ft = {
        c = [ "clang-format" ];
        cpp = [ "clang-format" ];
      };

      languages.clang.enable = true;
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        languages.clang.dap.enable = true;
        lsp.servers.clangd.enable = true;
        extraPackages = [ pkgs.clang-tools ];
      };
    };
}
