{
  flake.modules.nvf.core = {lib, ...}: {
    vim.diagnostics = {
      enable = true;
      config = {
        underline = true;
        severity_sort = true;
        signs.text = lib.generators.mkLuaInline ''
          {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          }
        '';
        virtual_lines = {
          current_line = true;
          severity = {
            min = "INFO";
          };
        };
        virtual_text = {
          current_line = false;
          severity = {
            min = "INFO";
          };
          spacing = 4;
          prefix = "●";
          source = "if_many";
        };
      };
    };
  };
}
