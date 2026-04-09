{ vim.keymaps = [
  {
    mode = ["t"];
    key = "<Esc><Esc>";
    action = "<C-\\><C-n>";
    desc = "Exit terminal mode";
  }
  {
    mode = ["n"];
    key = "<C-h>";
    action = "<cmd>TmuxNavigateLeft<CR>";
    desc = "Move focus to the left window";
  }
  {
    mode = ["n"];
    key = "<C-l>";
    action = "<cmd>TmuxNavigateRight<CR>";
    desc = "Move focus to the right window";
  }
  {
    mode = ["n"];
    key = "<C-j>";
    action = "<cmd>TmuxNavigateDown<CR>";
    desc = "Move focus to the lower window";
  }
  {
    mode = ["n"];
    key = "<C-k>";
    action = "<cmd>TmuxNavigateUp<CR>";
    desc = "Move focus to the upper window";
  }
]; }
