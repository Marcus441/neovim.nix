{
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
