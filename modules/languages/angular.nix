{
  flake.modules.nvf.core =
    { lib, ... }:
    {
      vim = {
        languages.angular.enable = true;

        filetype.pattern.".*%.html" = lib.mkLuaInline ''
          function(path)
            if vim.fs.root(path, "angular.json") then
              return "htmlangular"
            end
          end
        '';
      };
    };

  flake.modules.nvf.dev =
    { pkgs, ... }:
    {
      vim = {
        lsp.servers.angularls = {
          filetypes = [
            "htmlangular"
            "typescript"
          ];
          root_markers = [ "angular.json" ];
          workspace_required = true;
        };

        extraPackages = [ pkgs.angular-language-server ];
      };
    };
}
