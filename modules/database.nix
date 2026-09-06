{
  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
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
            vim.notify(("[db] no secrets file at %s"):format(path), vim.log.levels.WARN)
            return {}
          end
          local contents = f:read("*a")
          f:close()
          local ok, data = pcall(vim.json.decode, contents)
          if not ok then
            vim.notify(("[db] %s is not valid JSON"):format(path), vim.log.levels.ERROR)
            return {}
          end
          return data
        end

        local function pct(s)
          return (tostring(s):gsub("[^%w%-%.%_%~]", function(c)
            return ("%%%02X"):format(c:byte())
          end))
        end

        local engines = {
          sqlserver = {
            client = "sqlcmd",
            port = 1433,
            argv = function(s, port)
              return {
                "sqlcmd", "-S", s.host .. "," .. port,
                "-U", s.user, "-C", "-l", "5", "-h", "-1", "-W", "-Q",
                "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name;",
              }
            end,
            env = function(s) return { SQLCMDPASSWORD = s.password } end,
            url = function(s, port, db)
              return ("sqlserver://%s:%s@%s:%d/%s?trustServerCertificate=yes")
                     :format(pct(s.user), pct(s.password), s.host, port, pct(db))
            end,
          },
          postgres = {
            client = "psql",
            port = 5432,
            argv = function(s, port)
              return {
                "psql", "-wtAX", "-h", s.host, "-p", tostring(port),
                "-U", s.user, "-d", "postgres", "-c",
                "SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn ORDER BY 1;",
              }
            end,
            env = function(s)
              return { PGPASSWORD = s.password, PGCONNECT_TIMEOUT = "5" }
            end,
            url = function(s, port, db)
              return ("postgresql://%s:%s@%s:%d/%s")
                     :format(pct(s.user), pct(s.password), s.host, port, pct(db))
            end,
          },
        }

        local function enumerate(s)
          local engine = engines[s.type or "sqlserver"]
          if not engine then
            vim.notify(("[db] %s: unknown type %s"):format(s.name, tostring(s.type)),
              vim.log.levels.ERROR)
            return {}
          end
          if vim.fn.executable(engine.client) == 0 then
            vim.notify(("[db] %s is not on $PATH"):format(engine.client), vim.log.levels.ERROR)
            return {}
          end

          local port = s.port or engine.port
          local out = vim.system(engine.argv(s, port),
            { text = true, env = engine.env(s) }):wait(15000)

          if out.code ~= 0 then
            local why = vim.trim(out.stderr or "")
            if why == "" then why = vim.trim(out.stdout or "") end
            if why == "" then why = "exit " .. tostring(out.code) end
            vim.notify(("[db] %s: %s"):format(s.name, why), vim.log.levels.WARN)
            return {}
          end

          local conns = {}
          for line in (out.stdout or ""):gmatch("[^\r\n]+") do
            local db = vim.trim(line)
            if db ~= "" then
              table.insert(conns, {
                name = s.name .. "/" .. db,
                url = engine.url(s, port, db),
              })
            end
          end
          return conns
        end

        local function refresh()
          local all = {}
          for _, s in ipairs(load_servers()) do
            if s.url then
              table.insert(all, { name = s.name, url = s.url })
            else
              local ok, conns = pcall(enumerate, s)
              if ok then vim.list_extend(all, conns) end
            end
          end
          vim.g.dbs = all
          if vim.tbl_isempty(all) then
            vim.notify("[db] no databases enumerated", vim.log.levels.INFO)
          end
        end

        vim.g.dbs = {}

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

      augroups = [{name = "DboutCleanup";}];

      autocmds = [
        {
          event = ["FileType"];
          pattern = ["dbout"];
          desc = "Disable snacks indent/scope guides in query result buffers";
          group = "DboutCleanup";
          callback = lib.mkLuaInline ''
            function(args)
              vim.b[args.buf].snacks_indent = false
              vim.b[args.buf].snacks_scope = false
              vim.wo.wrap = false
            end
          '';
        }
      ];
    };
  };
}
