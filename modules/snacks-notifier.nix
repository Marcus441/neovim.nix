{
  flake.modules.nvf.gui = {
    vim.utility.snacks-nvim.setupOpts = {
      notifier = {
        enabled = true;
        timeout = 3000;
        style = "fancy";
      };

      styles.notification = {
        border = "solid";
        wo.winblend = 0;
      };
    };
  };
}
