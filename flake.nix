{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = {
    nixpkgs,
    nvf,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "vscode-extension-ms-dotnettools-csharp"
            ];
        };
        mkNeovim = modules:
          (nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [./core] ++ modules;
          }).neovim;
      in {
        packages = {
          default = mkNeovim [./min];
          min = mkNeovim [./min];
          gui = mkNeovim [./gui];
        };
      }
    );
}
