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
            return require("sql-dialect").known(ctx.buf)
          end
        '';
      };
    };
  };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim.extraPackages = [ pkgs.sqruff ];
    };
}
