{
  flake.modules.nvf.core = {lib, ...}: {
    vim.utility.snacks-nvim.setupOpts.statuscolumn = {
      enabled = false;
      # load-bearing: docs/decisions/statuscolumn.md#functions-not-lists
      left = lib.generators.mkLuaInline ''function() return { "fold", "sign", "git", "mark" } end'';
      right = lib.generators.mkLuaInline ''function() return {} end'';
    };

    vim.luaConfigRC.statuscolumn = ''
      -- Wraps snacks' renderer into stock neovim's gutter width: one icon
      -- slot, and a number cell the cursor line's number juts out left of
      _G.statuscolumn_jut = function()
        local ret = require("snacks.statuscolumn").get()
        local win = vim.g.statusline_winid
        local buf = vim.api.nvim_win_get_buf(win)
        local w = math.max(
          vim.wo[win].numberwidth - 1,
          #tostring(vim.api.nvim_buf_line_count(buf)) + 1
        )
        ret = ret:gsub("  %%T$", "%%T")
        return (ret:gsub("%%=(%d+) ", function(n)
          if vim.v.relnum == 0 then
            return n .. "%= "
          end
          return "%=" .. (" "):rep(w - #n) .. n .. " "
        end))
      end
      vim.o.statuscolumn = "%!v:lua.statuscolumn_jut()"
    '';
  };
}
