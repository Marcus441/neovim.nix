{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.angular = {
        enable = true;
        lsp.enable = false;
      };

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
      servers.angular-language-server = {
        filetypes = ["htmlangular" "typescript"];
        root_markers = lib.mkForce ["angular.json"];
        workspace_required = true;
      };
    };
  };
}
