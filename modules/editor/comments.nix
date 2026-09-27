{
  flake.modules.nvf.dev = {
    vim = {
      notes.todo-comments = {
        enable = true;
        mappings = {
          quickFix = null;
          telescope = null;
          trouble = null;
        };
      };

      keymaps = [
        {
          mode = [ "n" ];
          key = "<leader>st";
          action = "<cmd>lua Snacks.picker.todo_comments()<cr>";
          desc = "[S]earch [T]odos";
        }
        {
          mode = [ "n" ];
          key = "<leader>xt";
          action = "<cmd>TodoTrouble<cr>";
          desc = "Todos (Trouble)";
        }
      ];
    };
  };
}
