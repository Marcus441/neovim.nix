{
  flake.modules.nvf.core = {
    vim.utility.oil-nvim.enable = true;

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
