{
  flake.modules.nvf.core = {
    vim.utility.snacks-nvim.setupOpts.statuscolumn.enabled = false;

    vim.luaConfigRC.statuscolumn = ''
      -- Wraps snacks' renderer: the number cell is one wider than the last
      -- line's digits, so the cursor line's number always juts out left
      _G.statuscolumn_jut = function()
        local ret = require("snacks.statuscolumn").get()
        local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
        local w = #tostring(vim.api.nvim_buf_line_count(buf)) + 1
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
