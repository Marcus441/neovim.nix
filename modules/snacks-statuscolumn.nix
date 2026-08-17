{
  flake.modules.nvf.core = {
    # load-bearing: docs/decisions/statuscolumn.md#hand-rolled
    vim.luaConfigRC.statuscolumn = ''
      -- Native %s signs, relative numbers right-aligned, the cursor line's
      -- number jutting out left, closed folds' chevron in the trailing cell
      local foldicon
      _G.statuscolumn_jut = function()
        local win = vim.g.statusline_winid
        local nu = vim.wo[win].number
        local rnu = vim.wo[win].relativenumber
        if vim.v.virtnum ~= 0 or not (nu or rnu) then
          return "%s"
        end
        local lnum, relnum = vim.v.lnum, vim.v.relnum
        local n = tostring(rnu and (relnum > 0 or not nu) and relnum or lnum)
        local buf = vim.api.nvim_win_get_buf(win)
        local w = math.max(
          vim.wo[win].numberwidth - 1,
          #tostring(vim.api.nvim_buf_line_count(buf)) + 1
        )
        local trail = " "
        local closed = vim.api.nvim_win_call(win, function()
          return vim.fn.foldclosed(lnum)
        end)
        if closed == lnum then
          foldicon = foldicon
            or "%#Folded#" .. (vim.opt.fillchars:get().foldclose or "+") .. "%*"
          trail = foldicon
        end
        if relnum == 0 then
          return "%s" .. n .. "%=" .. trail
        end
        return "%s%=" .. (" "):rep(w - #n) .. n .. trail
      end
      vim.o.statuscolumn = "%!v:lua.statuscolumn_jut()"
    '';
  };
}
