{
  inputs,
  lib,
  ...
}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      # load-bearing: docs/decisions/nixpkgs.md#allowunfreepredicate
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vscode-extension-ms-dotnettools-csharp"
        ];
    };
  };
}
