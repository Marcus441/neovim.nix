{
  flake.modules.nvf.core = {
    vim = {
      languages.rust.enable = true;
      formatter.conform-nvim.setupOpts.formatters_by_ft.rust = [ "rustfmt" ];
    };
  };

  flake.modules.nvf.dev = {
    vim.languages.rust.extensions.crates-nvim.enable = true;
  };
}
