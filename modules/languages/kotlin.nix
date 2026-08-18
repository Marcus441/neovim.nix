{config, ...}: let
  inherit (config) preferPathExe;

  version = "262.9593.0";

  # load-bearing: docs/decisions/kotlin-lsp.md#the-server-is-vendored
  dists = {
    x86_64-linux = {
      arch = "";
      hash = "sha256-LZnY4Zj75KqPRIHjd5lyTOlIA7TqEqYLQWBA4/zXzF4=";
      extension = "tar.gz";
    };
    aarch64-linux = {
      arch = "-aarch64";
      hash = "sha256-IxeDHG5WB9BbfrwdplUzASXODj1m+/JFF9/ORC3rwU4=";
      extension = "tar.gz";
    };
    aarch64-darwin = {
      arch = "-aarch64";
      hash = "sha256-a6YCGnBrIeZM7zP34refGHwJEDIHIrstPtBa0RFexD8=";
      extension = "sit";
    };
    x86_64-darwin = {
      arch = "";
      hash = "sha256-Fzaf2pfIVBisJKs4qd9WshUio0aN/hk4Mv5FXBOSB0U=";
      extension = "sit";
    };
  };

  mkKotlinLsp = pkgs: lib: dist: let
    inherit (pkgs.stdenv.hostPlatform) isDarwin;
    archive = "kotlin-server-${version}${dist.arch}";
  in
    pkgs.stdenv.mkDerivation ({
        pname = "kotlin-lsp";
        inherit version;

        src = pkgs.fetchurl ({
            url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/${archive}.${dist.extension}";
            inherit (dist) hash;
          }
          # load-bearing: docs/decisions/kotlin-lsp.md#the-darwin-archive-is-a-zip
          // lib.optionalAttrs (dist.extension == "sit") {name = "${archive}.zip";});

        nativeBuildInputs =
          lib.optionals (!isDarwin) [pkgs.autoPatchelfHook]
          ++ [pkgs.makeWrapper]
          ++ lib.optionals isDarwin [pkgs.unzip];

        buildInputs = lib.optionals (!isDarwin) [pkgs.stdenv.cc.cc.lib pkgs.zlib];

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
      }
      # load-bearing: docs/decisions/kotlin-lsp.md#the-bundled-runtime-is-headless
      // lib.optionalAttrs (!isDarwin) {
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
      });
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

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    kotlinLspExe =
      if dists ? ${system}
      then preferPathExe pkgs "kotlin-lsp" (lib.getExe (mkKotlinLsp pkgs lib dists.${system}))
      else "kotlin-lsp";

    # load-bearing: docs/decisions/kotlin-lsp.md#one-daemon-serves-every-editor
    kotlinLspDaemon = lib.getExe (pkgs.writeShellScriptBin "kotlin-lsp-daemon" ''
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/kotlin-lsp"
      mkdir -p "$cache"

      probe() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

      exec 9>"$cache/.wrapper-lock"
      if ! ${pkgs.util-linux}/bin/flock -w 30 9; then
        echo "kotlin-lsp-daemon: timed out on $cache/.wrapper-lock" >&2
        exit 1
      fi

      if [ -r "$cache/daemon.pid" ] && [ -r "$cache/daemon.port" ] \
        && kill -0 "$(cat "$cache/daemon.pid")" 2>/dev/null \
        && probe "$(cat "$cache/daemon.port")"; then
        cat "$cache/daemon.port"
        exit 0
      fi

      if [ -r "$cache/daemon.pid" ]; then
        oldpid=$(cat "$cache/daemon.pid")
        if ${pkgs.procps}/bin/ps -p "$oldpid" -o command= 2>/dev/null | grep -q intellij-server; then
          kill "$oldpid" 2>/dev/null
          i=0
          while [ "$i" -lt 25 ] && kill -0 "$oldpid" 2>/dev/null; do
            sleep 0.2
            i=$((i + 1))
          done
          kill -9 "$oldpid" 2>/dev/null
        fi
      fi

      port=
      for candidate in 9999 10999 11999 12999; do
        if ! probe "$candidate"; then
          port=$candidate
          break
        fi
      done
      if [ -z "$port" ]; then
        echo "kotlin-lsp-daemon: ports 9999/10999/11999/12999 all busy" >&2
        exit 1
      fi

      ${pkgs.util-linux}/bin/setsid -f ${pkgs.runtimeShell} -c \
        'echo "$$" >"$1/daemon.pid" && exec ${kotlinLspExe} --multi-client --socket "127.0.0.1:$2" --system-path "$1"' \
        kotlin-lsp-daemon "$cache" "$port" \
        </dev/null >"$cache/daemon.log" 2>&1 9>&-
      echo "$port" >"$cache/daemon.port"

      i=0
      while [ "$i" -lt 150 ]; do
        if probe "$port"; then
          echo "$port"
          exit 0
        fi
        sleep 0.2
        if [ -r "$cache/daemon.pid" ] && ! kill -0 "$(cat "$cache/daemon.pid")" 2>/dev/null; then
          break
        fi
        i=$((i + 1))
      done
      echo "kotlin-lsp-daemon: no accept on 127.0.0.1:$port; see $cache/daemon.log" >&2
      exit 1
    '');
  in {
    vim = {
      languages.kotlin.extraDiagnostics.enable = true;

      lsp.servers.kotlin_lsp = {
        cmd = lib.mkLuaInline ''
          function(dispatchers)
            local out = vim.fn.system({ "${kotlinLspDaemon}" })
            if vim.v.shell_error ~= 0 then
              error("kotlin-lsp-daemon failed: " .. out)
            end
            local port = assert(tonumber(vim.trim(out)), "kotlin-lsp-daemon printed no port: " .. out)
            return vim.lsp.rpc.connect("127.0.0.1", port)(dispatchers)
          end
        '';
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
