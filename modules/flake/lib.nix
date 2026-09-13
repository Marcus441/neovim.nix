{lib, ...}: {
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Helpers shared by the nvf modules.";
  };

  # Runs the binary from $PATH when there is one, so a devshell's toolchain
  # wins, and the pinned package otherwise.
  config.flake.lib.preferPathExe = pkgs: name: fallbackExe:
    lib.getExe (pkgs.writeShellScriptBin name ''
      if command -v ${name} >/dev/null 2>&1; then
        exec ${name} "$@"
      fi
      exec ${fallbackExe} "$@"
    '');
}
