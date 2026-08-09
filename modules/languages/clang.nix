{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
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
      languages.clang = {
        enable = true;
        lsp.enable = lib.mkDefault false;
        dap.enable = lib.mkDefault false;
      };
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.clang = {
        lsp = {
          enable = true;
          servers = ["clangd"];
        };
        dap.enable = true;
      };

      lsp.servers.clangd.cmd = lib.mkForce [
        (preferPathExe pkgs "clangd" (lib.getExe' pkgs.clang-tools "clangd"))
      ];
    };
  };
}
