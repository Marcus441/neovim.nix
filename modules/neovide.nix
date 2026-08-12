{
  flake.modules.nvf.gui = {
    vim = {
      globals = {
        neovide_scroll_animation_length = 0.1;
        neovide_scroll_animation_far_lines = 0;
        neovide_position_animation_length = 0.0;
      };

      keymaps = [
        {
          mode = ["n"];
          key = "<C-=>";
          action = "function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end";
          lua = true;
          desc = "Increase window scale";
        }
        {
          mode = ["n"];
          key = "<C-->";
          action = "function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end";
          lua = true;
          desc = "Decrease window scale";
        }
      ];
    };
  };
}
