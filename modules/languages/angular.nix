{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.angular = {
        enable = true;
        # load-bearing: docs/decisions/angular.md#the-language-module-keeps-lsp-off
        lsp.enable = false;
      };

      # load-bearing: docs/decisions/angular.md#every-html-file-in-an-angular-workspace-is-a-template
      filetype.pattern.".*%.html" = lib.mkLuaInline ''
        function(path)
          if vim.fs.root(path, "angular.json") then
            return "htmlangular"
          end
        end
      '';
    };
  };

  flake.modules.nvf.dev = {lib, ...}: {
    vim.lsp = {
      presets.angular-language-server.enable = true;
      # load-bearing: docs/decisions/angular.md#only-an-angular-workspace-roots-the-server
      servers.angular-language-server = {
        filetypes = ["htmlangular" "typescript"];
        root_markers = lib.mkForce ["angular.json"];
        workspace_required = true;
      };
    };
  };
}
