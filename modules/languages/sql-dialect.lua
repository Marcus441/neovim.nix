local function of(buf)
  local explicit = vim.b[buf].sql_dialect or vim.g.sql_dialect
  if explicit then
    return explicit
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
  return nil
end

package.loaded["sql-dialect"] = {
  of = of,
  known = function(buf)
    return of(buf) ~= nil or vim.fs.root(buf, { ".sqruff" }) ~= nil
  end,
}
