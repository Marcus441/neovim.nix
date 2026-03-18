[
  {
    mode = ["n"];
    key = "<leader>sh";
    action = "<CMD> Telescope help_tags <CR>";
    desc = "[S]earch [H]elp";
  }
  {
    mode = ["n"];
    key = "<leader>sk";
    action = "<cmd>Telescope keymaps<cr>";
    desc = "[S]earch [K]eymaps";
  }
  {
    mode = ["n"];
    key = "<leader>sf";
    action = "<cmd>Telescope find_files<cr>";
    desc = "[S]earch [F]iles";
  }
  {
    mode = ["n"];
    key = "<leader>ss";
    action = "<cmd>Telescope builtin<cr>";
    desc = "[S]earch [S]elect Telescope";
  }
  {
    mode = ["n"];
    key = "<leader>sw";
    action = "<cmd>Telescope grep_string<cr>";
    desc = "[S]earch current [W]ord";
  }
  {
    mode = ["n"];
    key = "<leader>sg";
    action = "<cmd>Telescope live_grep<cr>";
    desc = "[S]earch by [G]rep";
  }
  {
    mode = ["n"];
    key = "<leader>sd";
    action = "<cmd>Telescope diagnostics<cr>";
    desc = "[S]earch [D]iagnostics";
  }
  {
    mode = ["n"];
    key = "<leader>sr";
    action = "<cmd>Telescope resume<cr>";
    desc = "[S]earch [R]esume";
  }
  {
    mode = ["n"];
    key = "<leader>s.";
    action = "<cmd>Telescope oldfiles<cr>";
    desc = "[S]earch Recent Files (\".\" for repeat)";
  }
  {
    mode = ["n"];
    key = "<leader><leader>";
    action = "<cmd>Telescope current_buffer_fuzzy_find<cr>";
    desc = "[ ] Find existing buffers";
  }
  {
    mode = ["n"];
    key = "<leader>/";
    action = "<cmd>Telescope buffers<cr>";
    desc = "[/] Fuzzily search in current buffer";
  }
]
