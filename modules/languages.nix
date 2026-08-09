{
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
          format.type = ["prettier"];
          lsp.enable = lib.mkDefault false;
        };
        csharp = {
          enable = true;
          treesitter.enable = true;
          lsp.enable = lib.mkDefault false;
        };
      };
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: let
    preferPath = name: fallbackExe:
      pkgs.writeShellScriptBin name ''
        if command -v ${name} >/dev/null 2>&1; then
          exec ${name} "$@"
        fi
        exec ${fallbackExe} "$@"
      '';
    preferPathExe = name: fallbackExe: lib.getExe (preferPath name fallbackExe);
  in {
    vim = {
      languages = {
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
        nix.lsp = {
          enable = true;
          servers = ["nixd"];
        };
        python.lsp.enable = true;
        typescript = {
          lsp = {
            enable = true;
            servers = [
              "typescript-language-server"
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

      lsp.servers = {
        clangd.cmd = lib.mkForce [
          (preferPathExe "clangd" (lib.getExe' pkgs.clang-tools "clangd"))
        ];
        rust-analyzer = {
          cmd = lib.mkForce [
            (preferPathExe "rust-analyzer" (lib.getExe pkgs.rust-analyzer))
          ];
          filetypes = ["rust"];
        };
        lua-language-server.cmd = lib.mkForce [
          (preferPathExe "lua-language-server" (lib.getExe pkgs.lua-language-server))
        ];
        basedpyright.cmd = lib.mkForce [
          (preferPathExe "basedpyright-langserver" (lib.getExe' pkgs.basedpyright "basedpyright-langserver"))
          "--stdio"
        ];
        typescript-language-server.cmd = lib.mkForce [
          (preferPathExe "typescript-language-server" (lib.getExe pkgs.typescript-language-server))
          "--stdio"
        ];
      };
    };
  };
}
