{
  flake.modules.nvf.dev =
    {
      pkgs,
      lib,
      ...
    }:
    {
      vim = {
        extraPlugins = {
          vim-dadbod = {
            package = pkgs.vimPlugins.vim-dadbod;
          };
          vim-dadbod-ui = {
            package = pkgs.vimPlugins.vim-dadbod-ui;
          };
          vim-dadbod-completion = {
            package = pkgs.vimPlugins.vim-dadbod-completion;
          };
        };
        extraPackages = [
          pkgs.sqlcmd
          pkgs.postgresql
        ];

        globals = {
          db_ui_use_nerd_fonts = 1;
          db_ui_use_nvim_notify = 1;
          db_ui_execute_on_save = 0;
          db_ui_auto_execute_table_helpers = 1;
        };

        autocomplete.blink-cmp.setupOpts.sources = {
          per_filetype.sql = [
            "dadbod"
            "snippets"
            "path"
            "buffer"
          ];
          providers.dadbod = {
            name = "Dadbod";
            module = "vim_dadbod_completion.blink";
            score_offset = 30;
          };
        };

        keymaps = [
          {
            mode = [ "n" ];
            key = "<leader>D";
            action = "<cmd>DBUIToggle<cr>";
            desc = "[D]atabase UI";
          }
        ];

        augroups = [ { name = "Dadbod"; } ];

        autocmds = [
          {
            event = [ "FileType" ];
            pattern = [ "sql" ];
            desc = "Execute query, or attach the file to a connection";
            group = "Dadbod";
            callback = lib.mkLuaInline ''
              function(args)
                vim.keymap.set({ "n", "x" }, "<M-CR>", function()
                  return vim.b.dbui_db_key_name and "<Plug>(DBUI_ExecuteQuery)" or "<Cmd>DBUIFindBuffer<CR>"
                end, { buffer = args.buf, expr = true, remap = true, silent = true, desc = "Execute query" })
              end
            '';
          }
          {
            event = [ "FileType" ];
            pattern = [ "dbout" ];
            desc = "Disable snacks indent/scope guides in query result buffers";
            group = "Dadbod";
            callback = lib.mkLuaInline ''
              function(args)
                vim.b[args.buf].snacks_indent = false
                vim.b[args.buf].snacks_scope = false
              end
            '';
          }
        ];
      };
    };
}
