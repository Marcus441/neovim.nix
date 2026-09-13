{
  flake.modules.nvf.images = {pkgs, ...}: {
    vim.extraPackages = [pkgs.imagemagick];

    vim.utility.snacks-nvim.setupOpts.image = {
      enabled = true;
      math.enabled = false;
    };
  };

  flake.modules.nvf.neovide.vim.utility.snacks-nvim.setupOpts.image.enabled = false;
}
