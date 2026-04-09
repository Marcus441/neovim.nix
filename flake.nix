{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = { self, nixpkgs, nvf, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        myNeovim = (nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./config ];
        }).neovim;
      in {
        packages.default = myNeovim;
        packages.nvim = myNeovim;
      }
    );
}
