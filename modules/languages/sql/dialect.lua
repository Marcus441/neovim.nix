local function of(buf)
  if vim.b[buf].sql_dialect then
    return vim.b[buf].sql_dialect
  end
  -- dadbod-ui sets b:db to the connection url on every query buffer
  local url = vim.b[buf].db
  if type(url) == "string" then
    if url:match("^sqlserver:") then
      return "tsql"
    end
    if url:match("^postgres") then
      return "postgres"
    end
  end
  return vim.g.sql_dialect
end

local function has_bind_params(buf)
  if not vim.b[buf].dbui_db_key_name then
    return false
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  return vim.fn.match(text, [[\(^\|[^:]\)\(]] .. vim.g.db_ui_bind_param_pattern .. [[\)]]) >= 0
end

package.loaded["sql-dialect"] = {
  of = of,
  has_bind_params = has_bind_params,
  known = function(buf)
    return of(buf) ~= nil or vim.fs.root(buf, { ".sqruff" }) ~= nil
  end,
}
