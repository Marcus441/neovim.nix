{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim.git = {
        vim-fugitive.enable = true;

        gitsigns = {
          enable = true;
          mappings = {
            toggleBlame = null;
            toggleDeleted = null;
          };
        };
      };

      vim.luaConfigRC.toggle-gitsigns = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
        Snacks.toggle({
          name = "Line blame",
          get = function()
            return require("gitsigns.config").config.current_line_blame
          end,
          set = function(enabled)
            require("gitsigns").toggle_current_line_blame(enabled)
          end,
        }):map("<leader>tb")

        Snacks.toggle({
          name = "Deleted lines",
          get = function()
            return require("gitsigns.config").config.show_deleted
          end,
          set = function(enabled)
            require("gitsigns").toggle_deleted(enabled)
          end,
        }):map("<leader>td")
      '';

      vim.binds.whichKey.register = {
        "<leader>g" = "Git";
        "<leader>h" = "Git hunk";
      };

      vim.keymaps = [
        {
          mode = [ "n" ];
          key = "<leader>gs";
          action = "<CMD>Git<CR>";
          desc = "Show [G]it [S]tatus";
        }
      ];
    };
}
