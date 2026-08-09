{
  flake.modules.nvf.core = {
    vim.git = {
      enable = true;
      gitsigns.enable = true;
    };

    vim.keymaps = [
      {
        mode = ["n"];
        key = "<leader>gs";
        action = "<CMD>Git<CR>";
        desc = "Show [G]it [S]tatus";
      }
    ];
  };
}
