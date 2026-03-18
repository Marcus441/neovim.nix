[
  # Clear highlights on search when pressing <Esc> in normal mode
  # See `:help hlsearch`
  {
    mode = ["n"];
    key = "<Esc>";
    action = "<cmd>nohlsearch<CR>";
    desc = "Clear search highlights";
  }
  # Git status
  {
    mode = ["n"];
    key = "<leader>gs";
    action = "<CMD>Git<CR>";
    desc = "Show Git status";
  }
  # Keep cursor to the left when appending lines
  {
    mode = ["n"];
    key = "J";
    action = "mzJ`z";
    desc = "Join line and keep cursor position";
  }
  # keep cursor in center when moving up and down half page and in finds
  {
    mode = ["n"];
    key = "<C-d>";
    action = "<C-d>zz";
    desc = "Half page down and center";
  }
  {
    mode = ["n"];
    key = "<C-u>";
    action = "<C-u>zz";
    desc = "Half page up and center";
  }
  {
    mode = ["n"];
    key = "n";
    action = "nzzzv";
    desc = "Next search match and center";
  }
  {
    mode = ["n"];
    key = "N";
    action = "Nzzzv";
    desc = "Previous search match and center";
  }
  # Exit terminal mode in the builtin terminal
  {
    mode = ["t"];
    key = "<Esc><Esc>";
    action = "<C-\\><C-n>";
    desc = "Exit terminal mode";
  }
  # Keybinds to make split navigation easier.
  # Use CTRL+<hjkl> to switch between windows
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
  # Move highlighted section up and down
  {
    mode = ["v"];
    key = "J";
    action = ":m '>+1<CR>gv=gv";
    desc = "Move visual block down";
  }
  {
    mode = ["v"];
    key = "K";
    action = ":m '<-2<CR>gv=gv";
    desc = "Move visual block up";
  }
  # Clipboard and void register
  # For these, the 'action' field needs to be a string representing the Vim command.
  # The '"_d' and '"+y' are normal mode commands, so you'd represent them as such.
  {
    mode = ["x"]; # Visual mode
    key = "<leader>p";
    action = "\"_dP"; # Pastes from system clipboard (") into void register (_)
    desc = "Paste into void register";
  }
  {
    mode = ["n"]; # Normal mode only
    key = "<leader>Y";
    action = "\"+Y"; # Yank line to system clipboard
    desc = "Yank line to system clipboard";
  }
  {
    mode = ["v"]; # Visual mode
    key = "<leader>y";
    action = "\"+y"; # Yank into system clipboard
    desc = "Yank to system clipboard";
  }
  {
    mode = ["n"]; # Normal mode
    key = "<leader>y";
    action = "\"+y"; # Yank into system clipboard
    desc = "Yank to system clipboard";
  }
  {
    mode = ["v"]; # Visual mode
    key = "<leader>d";
    action = "\"_d"; # Delete to void register (effectively delete without copying)
    desc = "Delete to void register";
  }
  {
    mode = ["n"]; # Normal mode
    key = "<leader>d";
    action = "\"_d"; # Delete to void register (effectively delete without copying)
    desc = "Delete to void register";
  }
  # undotree
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
    desc = "Toggle markview ";
  }
]
