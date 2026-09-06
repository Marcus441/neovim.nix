{
  flake.modules.nvf.core = {
    vim.luaConfigRC.sql-dialect = builtins.readFile ./sql-dialect.lua;

    vim.languages.sql = {
      enable = true;
      # load-bearing: docs/decisions/database.md#sql-declines-sqls
      lsp.enable = false;
      # load-bearing: docs/decisions/database.md#sqruff-refuses-an-unknown-dialect
      format.type = ["sqruff"];
      extraDiagnostics.enable = false;
    };
  };
}
