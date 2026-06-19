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

      -- Sensitive server list (client/company infra) loads from a runtime file
      -- OUTSIDE the repo. Point NVIM_DB_SERVERS at it; it can be plaintext-gitignored
      -- or dropped by sops/agenix. Shape: a JSON array of {name,host,port,user}.
      local function load_servers()
        local path = os.getenv("NVIM_DB_SERVERS")
        if not path or path == "" then return {} end
        local ok, data = pcall(function()
          return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
        end)
        if not ok then
          vim.notify("[db] bad NVIM_DB_SERVERS: " .. tostring(data), vim.log.levels.WARN)
          return {}
        end
        return data
      end

      local servers = {
        { name = "mssql2022", host = "127.0.0.1", port = 1433, user = "sa" },
        { name = "mssql2019", host = "127.0.0.1", port = 1435, user = "sa" },
      }
      vim.list_extend(servers, load_servers())

      -- Enumerate user databases on one server. No password here or on the
      -- command line: sqlcmd reads it from $SQLCMDPASSWORD in the environment.
      local function enumerate(s)
        local out = vim.system({
          "sqlcmd", "-S", s.host .. "," .. (s.port or 1433),
          "-U", s.user, "-C", "-h", "-1", "-W", "-Q",
          -- database_id > 4 skips master/tempdb/model/msdb; tighten with e.g.
          -- "AND name LIKE 'Client_%'" to limit to real client DBs.
          "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name;",
        }, { text = true }):wait()
        local conns = {}
        if out.code ~= 0 then
          vim.notify(("[db] %s: %s"):format(s.name, out.stderr or "failed"), vim.log.levels.WARN)
          return conns
        end
        for line in (out.stdout or ""):gmatch("[^\r\n]+") do
          local db = vim.trim(line)
          if db ~= "" then
            table.insert(conns, {
              name = s.name .. "/" .. db,
              url = ("sqlserver://%s@%s:%d/%s?trustServerCertificate=yes")
                    :format(s.user, s.host, s.port or 1433, db),
            })
          end
        end
        return conns
      end

      local function refresh()
        local all = {}
        for _, s in ipairs(servers) do
          local ok, conns = pcall(enumerate, s)
          if ok then vim.list_extend(all, conns) end
        end
        vim.g.dbs = all
        if vim.tbl_isempty(all) then
          vim.notify("[db] no databases (is SQLCMDPASSWORD set?)", vim.log.levels.INFO)
        end
      end

      vim.api.nvim_create_user_command("DBRefresh", refresh,
        { desc = "Re-enumerate SQL Server databases" })

      -- Enumerate lazily on first open so startup is never blocked by a query.
      vim.api.nvim_create_user_command("DBOpen", function()
        if not vim.g.dbs or vim.tbl_isempty(vim.g.dbs) then refresh() end
        vim.cmd("DBUIToggle")
      end, { desc = "Enumerate (if needed) and toggle DBUI" })

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
        action = "<CMD>DBOpen<CR>";
        desc = "[D]atabase UI";
      }
    ];
  };
}
