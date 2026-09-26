{
  flake.modules.nvf.core = {
    vim.utility.oil-nvim.enable = true;

    vim.keymaps = [
      {
        mode = [ "n" ];
        key = "-";
        desc = "Open parent directory";
        action = "<CMD>Oil<CR>";
      }
    ];
  };
}
