{
  aspectRequires.images = ["core"];

  flake.modules.nvf.images = {pkgs, ...}: {
    # load-bearing: docs/decisions/images.md#imagemagick-is-pinned-the-rest-of-the-toolchain-is-not
    vim.extraPackages = [pkgs.imagemagick];

    # load-bearing: docs/decisions/images.md#math-rendering-is-disabled
    vim.utility.snacks-nvim.setupOpts.image = {
      enabled = true;
      math.enabled = false;
    };
  };

  # load-bearing: docs/decisions/images.md#neovide-declines-image-rendering
  flake.modules.nvf.neovide.vim.utility.snacks-nvim.setupOpts.image.enabled = false;
}
