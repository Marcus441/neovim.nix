{
  flake.modules.nvf.neovide = {
    vim = {
      globals = {
        neovide_scroll_animation_length = 0.1;
        neovide_scroll_animation_far_lines = 0;
        neovide_position_animation_length = 0.0;

        # load-bearing: docs/decisions/neovide.md#stroke-weight
        neovide_underline_stroke_scale = 2.0;
        neovide_text_contrast = 0.75;
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
