{
  flake.modules.nvf.dev = {
    vim.lsp.servers = {
      yaml-language-server.settings.yaml = {
        # load-bearing: docs/decisions/openapi.md#schemastore-is-fetched-at-runtime
        schemaStore = {
          enable = true;
          url = "https://www.schemastore.org/api/json/catalog.json";
        };

        # load-bearing: docs/decisions/openapi.md#the-catalog-globs-are-narrow
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

        # load-bearing: docs/decisions/openapi.md#the-catalog-globs-are-narrow
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
