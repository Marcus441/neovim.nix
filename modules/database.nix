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
      # load-bearing: docs/decisions/database.md#the-clients-are-pinned-in-dev
      extraPackages = [pkgs.sqlcmd pkgs.postgresql];

      luaConfigRC.dadbod = ''
        vim.g.db_ui_use_nerd_fonts = 1
        vim.g.db_ui_use_nvim_notify = 1
        vim.g.db_ui_execute_on_save = 0

        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "sql", "mysql", "plsql" },
          callback = function(args)
            vim.bo[args.buf].omnifunc = "vim_dadbod_completion#omni"
            vim.keymap.set({ "n", "v" }, "<M-CR>", "<Plug>(DBUI_ExecuteQuery)",
              { buffer = args.buf, remap = true, silent = true, desc = "Execute query" })
          end,
        })
      '';
      keymaps = [
        {
          mode = ["n"];
          key = "<leader>D";
          lua = true;
          action = ''
            function()
              if vim.bo.filetype == "snacks_dashboard" then
                vim.cmd("enew")
              end
              vim.cmd("DBUIToggle")
            end
          '';
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
