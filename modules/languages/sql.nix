{
  flake.modules.nvf.core = {
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
