{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      luaConfigRC.sql-dialect = builtins.readFile ./dialect.lua;

      languages.sql = {
        enable = true;
        lsp.enable = false;
        format.type = ["sqruff"];
        extraDiagnostics.enable = false;
      };

      formatter.conform-nvim.setupOpts.formatters.sqruff = {
        command = lib.mkForce "sqruff";
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

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim.formatter.conform-nvim.setupOpts.formatters.sqruff.command =
      lib.mkOverride 40
      (preferPathExe pkgs "sqruff" (lib.getExe pkgs.sqruff));
  };
}
