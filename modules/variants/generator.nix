{
  config,
  lib,
  inputs,
  ...
}: let
  aspects = config.flake.modules.nvf or {};

  problems =
    lib.concatMap (
      name: let
        wanted = config.variants.${name}.aspects;
        unknown = lib.filter (a: !(aspects ? ${a})) wanted;
        unmet =
          lib.concatMap (
            a: lib.filter (r: !(lib.elem r wanted)) (config.aspectRequires.${a} or [])
          )
          wanted;
      in
        map (a: "variant ${name} names aspect ${a}, which no file declares") unknown
        ++ map (r: "variant ${name} is missing aspect ${r}, required by one it takes") unmet
    )
    (lib.attrNames config.variants);
in {
  options.variants = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.aspects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "The aspects this build is made of, in module order.";
      };
    });
    default = {};
    description = "What each build is: an aspect list, and nothing else.";
  };

  config.perSystem = {pkgs, ...}: let
    build = variant:
      (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = map (a: aspects.${a}) variant.aspects;
      })
      .neovim;

    built = lib.mapAttrs (_: build) config.variants;
  in {
    packages =
      lib.throwIf (problems != [])
      (lib.concatStringsSep "\n" (["variant wiring is inconsistent:"] ++ problems))
      (built // {default = built.min;});
  };
}
