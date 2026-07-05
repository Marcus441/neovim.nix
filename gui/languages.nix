{
  pkgs,
  lib,
  ...
}: let
  # LSP launcher that prefers the binary on $PATH (dev shell / direnv, so the
  # server matches the project toolchain) and falls back to the pinned
  # nixpkgs package so the LSP always works outside dev shells.
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
        lsp = {
          enable = true;
          # nvf launches "${package}/bin/rust-analyzer", so the wrapper binary
          # must be named rust-analyzer.
          package = preferPath "rust-analyzer" (lib.getExe pkgs.rust-analyzer);
        };
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

    # mkForce only replaces the preset's cmd; root_markers, capabilities and
    # on_attach from the preset are kept. roslyn-ls is not listed here: the
    # roslyn-nvim extension launches it from nvim's own PATH (extraPackages).
    lsp.servers = {
      clangd.cmd = lib.mkForce [
        (preferPathExe "clangd" (lib.getExe' pkgs.clang-tools "clangd"))
      ];
      lua-language-server.cmd = lib.mkForce [
        (preferPathExe "lua-language-server" (lib.getExe pkgs.lua-language-server))
      ];
      nil.cmd = lib.mkForce [
        (preferPathExe "nil" (lib.getExe pkgs.nil))
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
}
