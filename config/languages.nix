{
  vim = {
    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      # Systems
      assembly = {
        enable = true;
        lsp.enable = true;
      };
      clang = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["clangd"];
        };
        dap.enable = true;
      };
      rust = {
        enable = true;
        lsp.enable = true;
        extensions = {crates-nvim.enable = true;};
      };

      # Scripting
      bash = {
        enable = true;
        lsp.enable = true;
      };
      lua = {
        enable = true;
        lsp = {
          enable = true;
          lazydev.enable = true;
        };
      };
      nix = {
        enable = true;
        lsp.enable = true;
      };
      python = {
        enable = true;
        format.type = ["ruff"];
        lsp.enable = true;
      };

      # Web
      ts = {
        enable = true;
        lsp.enable = true;
        format.type = ["prettierd"];
        extensions.ts-error-translator.enable = true;
      };

      # Prose
      markdown = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["marksman"];
        };
        format = {
          enable = true;
          type = ["prettierd"];
        };
        extraDiagnostics = {
          enable = true;
          types = ["markdownlint-cli2"];
        };
        extensions.markview-nvim.enable = true;
      };
    };

    luaConfigRC.markdownlint = ''
      local config_path = vim.fn.expand("~/.markdownlint-cli2.yaml")
      if vim.fn.filereadable(config_path) == 0 then
        local f = io.open(config_path, "w")
        if f then
          f:write("MD055: false\nMD056: false\n")
          f:close()
        end
      end
    '';
  };
}
