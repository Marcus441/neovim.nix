{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim = {
        formatter.conform-nvim = {
          enable = true;
          setupOpts = {
            format_on_save = lib.mkLuaInline ''
              function(bufnr)
                if vim.g.disable_autoformat then
                  return
                end
                if vim.bo[bufnr].filetype == "cs" then
                  return { timeout_ms = 3000 }
                end
                return {}
              end
            '';
            format_after_save = null;
          };
        };

        luaConfigRC.toggle-format = lib.nvim.dag.entryAfter [ "pluginConfigs" ] ''
          Snacks.toggle({
            name = "Format on save",
            get = function()
              return not vim.g.disable_autoformat
            end,
            set = function(enabled)
              vim.g.disable_autoformat = not enabled
            end,
          }):map("<leader>tf")
        '';
      };
    };
}
