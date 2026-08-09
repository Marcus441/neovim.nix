{
  flake.modules.nvf.core = {
    vim.diagnostics = {
      enable = true;
      config = {
        underline = true;
        severity_sort = true;
        signs = true;
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
