{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim = {
        binds.whichKey = {
          enable = true;
          register."<leader>t" = "Toggle";
          setupOpts.delay = lib.mkLuaInline ''
            function(ctx)
              if vim.g.which_key_hidden then
                return 1e9
              end
              return ctx.plugin and 0 or 200
            end
          '';
        };

        keymaps = [
          {
            mode = [ "n" ];
            key = "<leader>?";
            action = "<cmd>lua require('which-key').show({ global = false })<cr>";
            desc = "Buffer local keymaps";
          }
          {
            mode = [ "n" ];
            key = "<leader>tk";
            action = "<cmd>lua vim.g.which_key_hidden = not vim.g.which_key_hidden<cr>";
            desc = "[T]oggle which-[K]ey";
          }
        ];
      };
    };
}
