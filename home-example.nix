# Example Home Manager configuration for consuming the neovim flake.
# Add this flake as an input in your system/home-manager flake:
#
#   inputs.neovim-config = {
#     url = "path:./neovim";  # or github:user/neovim-config
#     inputs.nixpkgs.follows = "nixpkgs";
#   };
#
# Then pass `inputs` through to your home-manager modules via
# `extraSpecialArgs = { inherit inputs; };`

{ pkgs, inputs, ... }:

{
  # Expose the minimal terminal editor globally as `nvim`
  home.packages = [
    inputs.neovim-config.packages.${pkgs.system}.min
  ];

  # Configure Neovide to exclusively use the GUI derivation
  programs.neovide = {
    enable = true;
    settings = {
      # Interpolate the absolute path to the GUI derivation's binary
      neovim-bin = "${inputs.neovim-config.packages.${pkgs.system}.gui}/bin/nvim";

      # Additional optimal Neovide settings
      fork = false;
      tabs = true;
    };
  };
}
