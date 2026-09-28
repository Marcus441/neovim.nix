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

        luaConfigRC.toggle-which-key = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
          Snacks.toggle({
            name = "Which-key popup",
            get = function()
              return not vim.g.which_key_hidden
            end,
            set = function(enabled)
              vim.g.which_key_hidden = not enabled
            end,
          }):map("<leader>tk")
        '';

        keymaps = [
          {
            mode = [ "n" ];
            key = "<leader>?";
            action = "<cmd>lua require('which-key').show({ global = false })<cr>";
            desc = "Buffer local keymaps";
          }
        ];
      };
    };
}
