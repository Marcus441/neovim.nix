{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      luaConfigRC.sql-dialect = builtins.readFile ./dialect.lua;

      languages.sql.enable = true;

      formatter.conform-nvim.setupOpts.formatters_by_ft.sql = [ "sqruff" ];

      formatter.conform-nvim.setupOpts.formatters.sqruff = {
        args = lib.mkLuaInline ''
          function(_, ctx)
            local dialect = require("sql-dialect").of(ctx.buf)
            if dialect then
              return { "fix", "--dialect", dialect, "$FILENAME" }
            end
            return { "fix", "$FILENAME" }
          end
        '';
        condition = lib.mkLuaInline ''
          function(_, ctx)
            local dialect = require("sql-dialect")
            return dialect.known(ctx.buf) and not dialect.has_bind_params(ctx.buf)
          end
        '';
      };
    };
  };

  flake.modules.nvf.dev =
    { pkgs, lib, ... }:
    {
      vim = {
        extraPackages = [ pkgs.sqruff ];

        diagnostics.nvim-lint.linters.sqruff.args = [
          "lint"
          "--format=json"
          "--parsing-errors"
          (lib.mkLuaInline ''
            function()
              return require("sql-dialect").lint_flag(0)
            end
          '')
          "-"
        ];

        augroups = [ { name = "SqlLint"; } ];

        autocmds = [
          {
            event = [ "BufWritePost" ];
            desc = "Lint SQL when the dialect is known";
            group = "SqlLint";
            callback = lib.mkLuaInline ''
              function(args)
                if vim.bo[args.buf].filetype == "sql" and require("sql-dialect").known(args.buf) then
                  require("lint").try_lint("sqruff")
                end
              end
            '';
          }
        ];
      };
    };
}
