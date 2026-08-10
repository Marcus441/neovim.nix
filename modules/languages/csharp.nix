{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.csharp = {
        enable = true;
        treesitter.enable = true;
        # load-bearing: docs/decisions/csharp.md#formatting-is-the-lsps-job
        format.enable = false;
        lsp.enable = lib.mkDefault false;
      };

      augroups = [{name = "CSharpIndent";}];
      autocmds = [
        {
          event = ["FileType"];
          pattern = ["cs"];
          desc = "Use smartindent for C# since treesitter has no indent queries";
          group = "CSharpIndent";
          callback = lib.mkLuaInline ''
            function()
              vim.bo.indentexpr = ""
              vim.bo.smartindent = true
            end
          '';
        }
      ];
    };
  };

  flake.modules.nvf.gui = {
    vim = {
      languages.csharp = {
        lsp = {
          enable = true;
          servers = ["roslyn-ls"];
        };
        extensions.roslyn-nvim = {
          enable = true;
          setupOpts.filewatching = "roslyn";
          setupOpts.extensions.razor.enabled = true;
        };
      };

      # load-bearing: docs/decisions/csharp.md#formatting-is-the-lsps-job
      formatter.conform-nvim.setupOpts.formatters_by_ft.cs = {lsp_format = "prefer";};

      # load-bearing: docs/decisions/csharp.md#organize-imports-goes-through-vimlspconfig
      luaConfigRC.roslyn-settings = ''
        vim.lsp.config("roslyn", {
          settings = {
            ["csharp|formatting"] = {
              dotnet_organize_imports_on_format = true,
            },
          },
        })
      '';
    };
  };
}
