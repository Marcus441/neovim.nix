{lib, ...}: {
  options.preferPathExe = lib.mkOption {
    type = lib.types.functionTo lib.types.raw;
    description = ''
      `pkgs -> name -> fallbackExe -> exe path`. Wraps a language server so a
      project's own toolchain wins over the pinned one inside a devshell.
      Capture it in an outer `let`; inside `flake.modules.*`, `config` is nvf's.
    '';
  };

  # load-bearing: docs/decisions/prefer-path.md#silent-fallback
  config.preferPathExe = pkgs: name: fallbackExe:
    lib.getExe (pkgs.writeShellScriptBin name ''
      if command -v ${name} >/dev/null 2>&1; then
        exec ${name} "$@"
      fi
      exec ${fallbackExe} "$@"
    '');
}
