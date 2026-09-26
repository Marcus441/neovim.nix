{
  flake.modules.nvf.core = {
    vim.diagnostics = {
      enable = true;
      config = {
        severity_sort = true;
        virtual_text = true;
      };
    };
  };
}
