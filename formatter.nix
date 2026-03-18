{
  programs.nvf.settings.vim = {
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        format_on_save = {};
        formatters_by_ft = {
          javascript = ["prettierd"];
          javascriptreact = ["prettierd"];
          typescript = ["prettierd"];
          typescriptreact = ["prettierd"];
          json = ["prettierd"];
          css = ["prettierd"];
          html = ["prettierd"];
          markdown = ["prettierd"];
        };
      };
    };
  };
}
