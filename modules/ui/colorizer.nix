{
  flake.modules.nvf.dev = {
    vim.ui.colorizer = {
      enable = true;
      setupOpts = {
        filetypes = {
          css = { };
          scss = { };
          html = { };
        };
        user_default_options.css = true;
      };
    };
  };
}
