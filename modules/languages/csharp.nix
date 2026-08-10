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
      extraPackages = [pkgs.netcoredbg pkgs.dotnet-sdk_8];

      augroups = [{name = "RoslynFidget";}];
      autocmds = [
        {
          event = ["VimEnter"];
          desc = "Divert roslyn.nvim notifications to fidget, wrapping whichever notify won startup";
          group = "RoslynFidget";
          # load-bearing: docs/decisions/csharp.md#roslyn-notifications-go-through-fidget
          callback = lib.mkLuaInline ''
            function()
              local delegate = vim.notify
              local wrapper
              wrapper = function(msg, level, opts)
                local roslyn = (opts and opts.title == "roslyn.nvim")
                  or (type(msg) == "string" and msg:find("roslyn.nvim", 1, true))
                if roslyn then
                  require("lz.n").trigger_load("fidget-nvim")
                  return require("fidget").notify(msg, level, opts)
                end
                vim.notify = delegate
                local ok, res = pcall(delegate, msg, level, opts)
                delegate = vim.notify
                vim.notify = wrapper
                assert(ok, res)
                return res
              end
              vim.notify = wrapper
            end
          '';
        }
      ];
    };
  };
}
