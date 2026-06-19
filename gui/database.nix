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
      local function load_servers()
        local path = os.getenv("NVIM_DB_SECRETS")
          or (os.getenv("HOME") .. "/.config/nvim-secrets/servers.json")
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

      local function enumerate(s)
        local port = s.port or 1433
        local out = vim.system({
          "sqlcmd", "-S", s.host .. "," .. port,
          "-U", s.user, "-C", "-h", "-1", "-W", "-Q",
          "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name;",
        }, { text = true, env = { SQLCMDPASSWORD = s.password } }):wait()

        local conns = {}
        local stdout = out.stdout or ""

        if out.code ~= 0
          or stdout:match("[Pp]assword:")
          or stdout:match("[Ww]arning")
          or stdout:match("[Ee]rror")
        then
          vim.notify(("[db] %s: enumeration failed (auth?)"):format(s.name), vim.log.levels.WARN)
          return conns
        end

        for line in stdout:gmatch("[^\r\n]+") do
          local db = vim.trim(line)
          -- real DB names here are single tokens; reject anything with spaces/colons
          if db ~= "" and not db:match("[:%s]") then
            table.insert(conns, {
              name = s.name .. "/" .. db,
              url = ("sqlserver://%s:%s@%s:%d/%s?trustServerCertificate=yes")
                    :format(s.user, vim.uri_encode(s.password), s.host, port, db),
            })
          end
        end
        return conns
      end

      local function refresh()
        local all = {}
        for _, s in ipairs(load_servers()) do
          local ok, conns = pcall(enumerate, s)
          if ok then vim.list_extend(all, conns) end
        end
        vim.g.dbs = all
        if vim.tbl_isempty(all) then
          vim.notify("[db] no databases enumerated", vim.log.levels.INFO)
        end
      end

      vim.g.dbs = {}
      refresh()  -- runs at startup; reads file, enumerates both instances

      vim.api.nvim_create_user_command("DBRefresh", refresh,
        { desc = "Re-enumerate databases from the secrets file" })

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
