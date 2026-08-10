{config, ...}: let
  inherit (config) preferPathExe;

  version = "262.9593.0";

  # load-bearing: docs/decisions/kotlin-lsp.md#the-server-is-vendored
  dists = {
    x86_64-linux = {
      arch = "";
      hash = "sha256-LZnY4Zj75KqPRIHjd5lyTOlIA7TqEqYLQWBA4/zXzF4=";
    };
    aarch64-linux = {
      arch = "-aarch64";
      hash = "sha256-IxeDHG5WB9BbfrwdplUzASXODj1m+/JFF9/ORC3rwU4=";
    };
  };

  mkKotlinLsp = pkgs: lib: dist:
    pkgs.stdenv.mkDerivation {
      pname = "kotlin-lsp";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}${dist.arch}.tar.gz";
        inherit (dist) hash;
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper];
      buildInputs = [pkgs.stdenv.cc.cc.lib pkgs.zlib];

      # load-bearing: docs/decisions/kotlin-lsp.md#the-bundled-runtime-is-headless
      autoPatchelfIgnoreMissingDeps = [
        "libasound.so.2"
        "libfreetype.so.6"
        "libwayland-client.so.0"
        "libwayland-cursor.so.0"
        "libX11.so.6"
        "libXext.so.6"
        "libXi.so.6"
        "libxkbcommon.so.0"
        "libXrender.so.1"
        "libXtst.so.6"
      ];

      dontConfigure = true;
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/libexec/kotlin-lsp
        cp -r . $out/libexec/kotlin-lsp
        makeWrapper $out/libexec/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp
        runHook postInstall
      '';

      meta = {
        description = "Official JetBrains language server for Kotlin";
        homepage = "https://github.com/Kotlin/kotlin-lsp";
        license = lib.licenses.unfree;
        mainProgram = "kotlin-lsp";
        platforms = lib.attrNames dists;
      };
    };
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.kotlin = {
        enable = true;
        lsp.enable = false;
      };

      augroups = [{name = "KotlinIndent";}];
      autocmds = [
        # load-bearing: docs/decisions/kotlin-lsp.md#kotlin-has-no-treesitter-indent-query
        {
          event = ["FileType"];
          pattern = ["kotlin"];
          desc = "Restore Neovim's own Kotlin indent since treesitter has no indent queries";
          group = "KotlinIndent";
          callback = lib.mkLuaInline ''
            function()
              if vim.fn.exists("*GetKotlinIndent") == 1 then
                vim.bo.indentexpr = "GetKotlinIndent()"
              else
                vim.bo.indentexpr = ""
                vim.bo.smartindent = true
              end
            end
          '';
        }
      ];
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    kotlinLspExe =
      if dists ? ${system}
      then preferPathExe pkgs "kotlin-lsp" (lib.getExe (mkKotlinLsp pkgs lib dists.${system}))
      else "kotlin-lsp";

    # load-bearing: docs/decisions/kotlin-lsp.md#the-index-cache-is-persistent
    kotlinLspCached = lib.getExe (pkgs.writeShellScriptBin "kotlin-lsp-cached" ''
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/kotlin-lsp"
      mkdir -p "$cache"
      exec 9>"$cache/.wrapper-lock"
      if ${pkgs.util-linux}/bin/flock -n 9; then
        exec ${kotlinLspExe} --system-path "$cache" "$@"
      fi
      exec ${kotlinLspExe} --system-path "$(mktemp -d -t kotlin-lsp-overflow.XXXXXX)" "$@"
    '');
  in {
    vim = {
      languages.kotlin.extraDiagnostics.enable = true;

      lsp.servers.kotlin_lsp = {
        cmd = [kotlinLspCached "--stdio"];
        filetypes = ["kotlin"];
        workspace_required = true;
        root_markers = [
          "settings.gradle.kts"
          "settings.gradle"
          "build.gradle.kts"
          "build.gradle"
          "pom.xml"
        ];
      };

      # load-bearing: docs/decisions/kotlin-lsp.md#formatting-is-the-servers-job
      formatter.conform-nvim.setupOpts.formatters_by_ft.kotlin = {
        lsp_format = "fallback";
        timeout_ms = 2000;
      };

      diagnostics.nvim-lint.linters.ktlint.cmd =
        lib.mkForce
        (preferPathExe pkgs "ktlint" (lib.getExe pkgs.ktlint));
    };
  };
}
