{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim.formatter.conform-nvim.setupOpts.formatters_by_ft = lib.genAttrs [
        "css"
        "html"
        "htmlangular"
        "javascript"
        "javascriptreact"
        "json"
        "jsonc"
        "markdown"
        "sass"
        "scss"
        "typescript"
        "typescriptreact"
        "yaml"
        "yaml.gitlab"
      ] (_: [ "prettierd" ]);
    };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim.extraPackages = [ pkgs.prettierd ];
    };
}
