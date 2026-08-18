{
  flake.modules.nvf.core = {
    vim.utility.oil-nvim = {
      enable = true;

      # load-bearing: docs/decisions/theme.md#picker-blocks
      setupOpts.confirmation = {
        border = "solid";
        win_options.winhighlight = "NormalFloat:OilConfirm,FloatBorder:OilConfirmBorder";
      };
    };

    vim.keymaps = [
      {
        mode = ["n"];
        key = "-";
        desc = "Toggle Oil in CWD";
        action = "<CMD>Oil<CR>";
      }
    ];
  };
}
