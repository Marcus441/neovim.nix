{
  flake.modules.nvf.core = {
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
