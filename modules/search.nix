{
  flake.modules.nvf.core = {
    vim.keymaps = [
      {
        mode = ["n"];
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
        desc = "Clear search highlights";
      }
    ];
  };
}
