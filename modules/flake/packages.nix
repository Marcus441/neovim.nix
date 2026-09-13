{
  config,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: let
    build = aspects:
      (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = map (aspect: config.flake.modules.nvf.${aspect}) aspects;
      })
      .neovim;
  in {
    packages = rec {
      min = build ["core"];
      full = build ["core" "dev" "images"];
      gui = build ["core" "dev" "neovide"];
      default = min;
    };
  };
}
