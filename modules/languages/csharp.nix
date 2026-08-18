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

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    vim = {
      languages.csharp = {
        lsp = {
          enable = true;
          servers = ["roslyn-ls"];
        };
        extensions.roslyn-nvim = {
          enable = true;
          setupOpts.filewatching = "roslyn";
          # load-bearing: docs/decisions/csharp.md#razor-is-disabled-until-the-pin-catches-up
          setupOpts.extensions.razor.enabled = false;
          # load-bearing: docs/decisions/csharp.md#roslyn-notifications-go-through-fidget
          setupOpts.silent = true;
        };
      };

      # load-bearing: docs/decisions/csharp.md#formatting-is-the-lsps-job
      formatter.conform-nvim.setupOpts.formatters_by_ft.cs = {lsp_format = "prefer";};

      # load-bearing: docs/decisions/csharp.md#organize-imports-goes-through-vimlspconfig
      luaConfigRC.roslyn-settings = ''
        vim.lsp.config("roslyn", {
          cmd = { "Microsoft.CodeAnalysis.LanguageServer", "--stdio" },
          settings = {
            ["csharp|formatting"] = {
              dotnet_organize_imports_on_format = true,
            },
          },
        })
      '';

      debugger.nvim-dap = {
        # load-bearing: docs/decisions/csharp.md#netcoredbg
        adapters.coreclr = {
          type = "executable";
          command = "${pkgs.netcoredbg}/bin/netcoredbg";
          args = ["--interpreter=vscode"];
        };
        configurations.cs = [
          {
            type = "coreclr";
            name = "launch - netcoredbg";
            request = "launch";
            program = lib.mkLuaInline ''
              function()
                return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
              end
            '';
          }
        ];
      };

      # load-bearing: docs/decisions/csharp.md#netcoredbg
      extraPackages = [pkgs.netcoredbg pkgs.dotnet-sdk_10];

      augroups = [{name = "RoslynFidget";}];
      autocmds = [
        {
          event = ["User"];
          pattern = ["RoslynOnInit"];
          desc = "Report roslyn initialization through fidget, replacing the silenced notify";
          group = "RoslynFidget";
          # load-bearing: docs/decisions/csharp.md#roslyn-notifications-go-through-fidget
          callback = lib.mkLuaInline ''
            function(ev)
              require("lz.n").trigger_load("fidget-nvim")
              local target = ev.data.type == "solution" and ev.data.target or "project"
              require("fidget").notify("Initializing Roslyn for: " .. target, vim.log.levels.INFO)
            end
          '';
        }
        {
          event = ["User"];
          pattern = ["RoslynInitialized"];
          desc = "Report roslyn initialization through fidget, replacing the silenced notify";
          group = "RoslynFidget";
          callback = lib.mkLuaInline ''
            function()
              require("lz.n").trigger_load("fidget-nvim")
              require("fidget").notify("Roslyn project initialization complete", vim.log.levels.INFO)
            end
          '';
        }
      ];
    };
  };
}
