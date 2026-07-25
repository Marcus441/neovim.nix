{
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
      nix.lsp.enable = true;
      python.lsp.enable = true;
      kotlin.lsp = {
        enable = true;
        servers = ["kotlin-language-server"];
      };
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
      kotlin-language-server = {
        cmd = lib.mkForce [
          (preferPathExe "kotlin-language-server" (lib.getExe pkgs.kotlin-language-server))
        ];
        root_markers = [
          "settings.gradle.kts"
          "settings.gradle"
          "gradlew"
        ];
        init_options = lib.mkForce (lib.generators.mkLuaInline "vim.empty_dict()");
        on_attach = lib.generators.mkLuaInline ''
          function(client, _)
            client.server_capabilities.documentHighlightProvider = nil
            client.server_capabilities.documentFormattingProvider = nil
            client.server_capabilities.documentRangeFormattingProvider = nil
          end
        '';
      };
    };

    formatter.conform-nvim.setupOpts = {
      formatters_by_ft.kotlin = ["ktlint"];
      formatters.ktlint.command = preferPathExe "ktlint" (lib.getExe pkgs.ktlint);
      # ktlint pays JVM startup on every run, so a synchronous format on
      # save blocks the editor for seconds. Route kotlin through conform's
      # async after-save path instead; everything else stays sync.
      format_on_save = lib.mkForce (lib.generators.mkLuaInline ''
        function(bufnr)
          if vim.bo[bufnr].filetype == "kotlin" then
            return
          end
          return {timeout_ms = 500, lsp_format = "fallback"}
        end
      '');
      format_after_save = lib.mkForce (lib.generators.mkLuaInline ''
        function(bufnr)
          if vim.bo[bufnr].filetype ~= "kotlin" then
            return
          end
          return {lsp_format = "fallback"}
        end
      '');
    };
  };
}
