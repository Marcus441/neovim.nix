{
  flake.modules.nvf.dev = {
    vim.lsp.servers = {
      yaml-language-server.settings.yaml = {
        schemaStore = {
          enable = true;
          url = "https://www.schemastore.org/api/json/catalog.json";
        };

        schemas."https://www.schemastore.org/openapi-3.X.json" = [
          "openapi.yaml"
          "openapi.yml"
          "**/openapi/*.yaml"
          "**/openapi/*.yml"
          "**/api/*.yaml"
          "**/api/*.yml"
        ];
      };

      vscode-json-language-server.settings.json = {
        validate.enable = true;

        schemas = [
          {
            fileMatch = [
              "openapi.json"
              "*.openapi.json"
              "**/openapi/*.json"
            ];
            url = "https://www.schemastore.org/openapi-3.X.json";
          }
        ];
      };
    };
  };
}
