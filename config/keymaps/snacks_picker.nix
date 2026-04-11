{
  vim.keymaps = [
    {
      mode = ["n"];
      key = "<leader>sh";
      action = "<cmd>lua Snacks.picker.help()<cr>";
      desc = "[S]earch [H]elp";
    }
    {
      mode = ["n"];
      key = "<leader>sk";
      action = "<cmd>lua Snacks.picker.keymaps()<cr>";
      desc = "[S]earch [K]eymaps";
    }
    {
      mode = ["n"];
      key = "<leader>sf";
      action = "<cmd>lua Snacks.picker.files()<cr>";
      desc = "[S]earch [F]iles";
    }
    {
      mode = ["n"];
      key = "<leader>ss";
      action = "<cmd>lua Snacks.picker.pickers()<cr>";
      desc = "[S]earch [S]elect Picker";
    }
    {
      mode = ["n"];
      key = "<leader>sp";
      action = "<cmd>lua Snacks.picker.projects()<cr>";
      desc = "[S]earch [P]rojects";
    }
    {
      mode = ["n"];
      key = "<leader>sm";
      action = "<cmd>lua Snacks.picker.marks()<cr>";
      desc = "[S]earch [M]arks";
    }
    {
      mode = ["n"];
      key = "<leader>sw";
      action = "<cmd>lua Snacks.picker.grep_word()<cr>";
      desc = "[S]earch current [W]ord";
    }
    {
      mode = ["n"];
      key = "<leader>sg";
      action = "<cmd>lua Snacks.picker.grep()<cr>";
      desc = "[S]earch by [G]rep";
    }
    {
      mode = ["n"];
      key = "<leader>sd";
      action = "<cmd>lua Snacks.picker.diagnostics()<cr>";
      desc = "[S]earch [D]iagnostics";
    }
    {
      mode = ["n"];
      key = "<leader>sr";
      action = "<cmd>lua Snacks.picker.resume()<cr>";
      desc = "[S]earch [R]esume";
    }
    {
      mode = ["n"];
      key = "<leader>s.";
      action = "<cmd>lua Snacks.picker.recent()<cr>";
      desc = "[S]earch Recent Files (\".\" for repeat)";
    }
    {
      mode = ["n"];
      key = "<leader><leader>";
      action = "<cmd>lua Snacks.picker.buffers()<cr>";
      desc = "[ ] Find existing buffers";
    }
    {
      mode = ["n"];
      key = "<leader>/";
      action = "<cmd>lua Snacks.picker.lines()<cr>";
      desc = "[/] Fuzzily search in current buffer";
    }
  ];
}
