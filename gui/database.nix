{pkgs, ...}: {
  vim = {
    extraPlugins = {
      vim-dadbod = {
        package = pkgs.vimPlugins.vim-dadbod;
      };
      vim-dadbod-ui = {
        package = pkgs.vimPlugins.vim-dadbod-ui;
        after = ["vim-dadbod"];
      };
      vim-dadbod-completion = {
        package = pkgs.vimPlugins.vim-dadbod-completion;
        after = ["vim-dadbod"];
      };
    };
    luaConfigRC.dadbod = ''
      vim.g.db_ui_use_nerd_fonts = 1

      -- Connections (with passwords) live in a gitignored file OUTSIDE the repo.
      -- Shape: a JSON array of { "name": "...", "url": "sqlserver://..." }.
      -- dadbod-ui expands each server's databases in the drawer natively, so no
      -- enumeration is needed. Override the path with NVIM_DB_SECRETS if you like.
      local function load_dbs()
        local path = os.getenv("NVIM_DB_SECRETS")
          or (os.getenv("HOME") .. "/.config/nvim-secrets/dbs.json")
        local f = io.open(path, "r")
        if not f then
          vim.notify("[db] no secrets file at " .. path, vim.log.levels.WARN)
          return {}
        end
        local contents = f:read("*a")
        f:close()
        local ok, data = pcall(vim.json.decode, contents)
        if not ok then
          vim.notify("[db] bad JSON in " .. path .. ": " .. tostring(data), vim.log.levels.WARN)
          return {}
        end
        return data
      end

      vim.g.dbs = load_dbs()

      -- Reload connections from the secrets file without restarting nvim.
      vim.api.nvim_create_user_command("DBReload", function()
        vim.g.dbs = load_dbs()
      end, { desc = "Reload DB connections from the secrets file" })

      -- <C-x><C-o> table/column completion in SQL buffers.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function() vim.bo.omnifunc = "vim_dadbod_completion#omni" end,
      })
    '';
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>D";
        action = "<CMD>DBUIToggle<CR>";
        desc = "[D]atabase UI";
      }
    ];
  };
}
