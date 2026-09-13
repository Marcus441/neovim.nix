{
  flake.modules.nvf.dev = {
    vim.ui.colorizer = {
      enable = true;
      setupOpts = {
        filetypes = {
          "*" = {
            RGB = true;
            RRGGBB = true;
            always_update = true;
            css = true;
            mode = "background";
          };
        };
      };
    };
  };
}
