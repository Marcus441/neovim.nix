{
  flake.modules.nvf.core = {
    vim.utility.snacks-nvim.setupOpts.statuscolumn.enabled = false;

    vim.luaConfigRC.statuscolumn = ''
      -- Wraps snacks' renderer: the cursor line's number left-aligns and juts out
      _G.statuscolumn_jut = function()
        local ret = require("snacks.statuscolumn").get()
        if vim.v.relnum == 0 then
          ret = ret:gsub("%%=(%d+) ", "%1%%= ")
        end
        return ret
      end
      vim.o.statuscolumn = "%!v:lua.statuscolumn_jut()"
    '';
  };
}
