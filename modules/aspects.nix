{lib, ...}: {
  options = {
    flake.modules = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
      default = {};
      description = ''
        Modules grouped by class, then by aspect. Every file contributing to
        `nvf.<aspect>` merges into one deferred module, in import order.
      '';
    };

    aspectRequires = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.listOf lib.types.str);
      default = {};
      description = ''
        Aspects an aspect's contents depend on. Declared by the file that
        creates the dependency; checked by the variant generator.
      '';
    };
  };
}
