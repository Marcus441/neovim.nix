{ vim.keymaps = [
  {
    mode = ["n"];
    key = "<Esc>";
    action = "<cmd>nohlsearch<CR>";
    desc = "Clear search highlights";
  }
  {
    mode = ["n"];
    key = "<leader>u";
    action = "<CMD>UndotreeToggle<CR>";
    desc = "[U]ndotree";
  }
  {
    mode = ["n"];
    key = "<C-m>";
    action = "<cmd>Markview<cr>";
    desc = "Toggle markview";
  }
]; }
