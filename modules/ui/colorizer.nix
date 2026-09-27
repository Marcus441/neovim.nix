{
  flake.modules.nvf.dev =
    let
      filetypes = [
        "css"
        "scss"
        "html"
      ];
    in
    {
      vim.lazy.plugins.nvim-colorizer-lua = {
        package = "nvim-colorizer-lua";
        setupModule = "colorizer";
        setupOpts = {
          inherit filetypes;
          user_default_options.css = true;
        };
        ft = filetypes;
      };
    };
}
