{
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = lib.mkDefault false;
    };
  };

  flake.modules.nvf.dev = {
    vim.languages.enableExtraDiagnostics = true;
  };
}
