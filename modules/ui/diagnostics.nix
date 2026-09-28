{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim.diagnostics = {
        enable = true;
        config = {
          severity_sort = true;
          virtual_text.current_line = false;
          virtual_lines = {
            current_line = true;
            format = lib.mkLuaInline ''
              function(diagnostic)
                local window = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
                local connector = 6
                local width = math.max(window.width - window.textoff - diagnostic.col - connector, 20)
                local lines = {}
                for _, paragraph in ipairs(vim.split(diagnostic.message, "\n")) do
                  local line = ""
                  for word in paragraph:gmatch("%S+") do
                    if line ~= "" and #line + #word >= width then
                      lines[#lines + 1] = line
                      line = word
                    else
                      line = line == "" and word or line .. " " .. word
                    end
                  end
                  lines[#lines + 1] = line
                end
                return table.concat(lines, "\n")
              end
            '';
          };
        };
      };
    };
}
