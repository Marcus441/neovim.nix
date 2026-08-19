{
  flake.modules.nvf.dev = {lib, ...}: {
    vim = {
      utility.direnv.enable = true;

      globals.direnv_silent_load = 1;

      # load-bearing: docs/decisions/direnv.md#its-own-group
      luaConfigRC.direnv-fidget-group = ''
        -- The fidget group direnv reports through, registered on first use.
        _DIRENV_FIDGET_GROUP = function()
          local frame = require("fidget.spinner").animate("dots", 1)
          require("fidget.notification").set_config("direnv", {
            name = "direnv",
            icon = function(now, items)
              for _, item in ipairs(items) do
                if not item.data then
                  return frame(now)
                end
              end
              return "✓"
            end,
            annote_style = "Comment",
            ttl = 3,
          }, false)
        end
      '';

      augroups = [{name = "DirenvFidget";}];

      autocmds = [
        # load-bearing: docs/decisions/direnv.md#the-stderr-sink
        {
          event = ["VimEnter"];
          desc = "Divert direnv.vim's stderr from its script-local dict into g:direnv_stderr";
          group = "DirenvFidget";
          callback = lib.mkLuaInline ''
            function()
              vim.cmd([[
                function! direnv#on_stderr(_, data, ...) abort
                  let g:direnv_stderr = get(g:, 'direnv_stderr', []) + a:data
                endfunction
              ]])
            end
          '';
        }
        # load-bearing: docs/decisions/direnv.md#the-spinner
        {
          event = ["VimEnter" "DirChanged"];
          desc = "Open a fidget spinner, but only for an export slow enough to be worth one";
          group = "DirenvFidget";
          callback = lib.mkLuaInline ''
            function()
              if vim.fn.executable(vim.g.direnv_cmd or "direnv") ~= 1 then
                return
              end

              _DIRENV_EXPORT_ID = (_DIRENV_EXPORT_ID or 0) + 1
              local id = _DIRENV_EXPORT_ID
              local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")

              vim.defer_fn(function()
                if _DIRENV_EXPORT_ID ~= id then
                  return
                end

                require("lz.n").trigger_load("fidget-nvim")
                _DIRENV_FIDGET_GROUP()

                require("fidget").notify(cwd, nil, {
                  group = "direnv",
                  key = "direnv",
                  ttl = 99999,
                })
              end, (vim.g.direnv_interval or 500) + 200)
            end
          '';
        }
        {
          event = ["User"];
          pattern = ["DirenvLoaded"];
          desc = "Cancel or close that spinner, reporting whatever direnv wrote to stderr";
          group = "DirenvFidget";
          callback = lib.mkLuaInline ''
            function()
              _DIRENV_EXPORT_ID = (_DIRENV_EXPORT_ID or 0) + 1

              local lines = vim.g.direnv_stderr or {}
              vim.g.direnv_stderr = {}

              local kept = {}
              for _, line in ipairs(lines) do
                line = line:gsub("\27%[[%d;]*m", ""):gsub("^direnv: ", "")
                if line:match("%S") then
                  table.insert(kept, line)
                end
              end

              require("lz.n").trigger_load("fidget-nvim")
              _DIRENV_FIDGET_GROUP()

              if #kept == 0 then
                local notification = require("fidget.notification")
                notification.notify(nil, nil, {
                  group = "direnv",
                  key = "direnv",
                  update_only = true,
                  skip_history = true,
                })
                vim.schedule(function()
                  notification.remove("direnv", "direnv")
                end)
                return
              end

              local msg = table.concat(kept, "\n")
              local level = msg:lower():find("error", 1, true) and vim.log.levels.WARN or vim.log.levels.INFO

              require("fidget").notify(msg, level, {
                group = "direnv",
                key = "direnv",
                data = true,
                ttl = 0,
              })
            end
          '';
        }
      ];
    };
  };
}
