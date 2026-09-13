{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.csharp = {
        enable = true;
        treesitter.enable = true;
        format.type = ["csharpier"];
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters.csharpier = {
        command = lib.mkForce null;
        "inherit" = false;
        format = lib.mkLuaInline ''
          function(self, ctx, lines, callback)
            return require("csharpier-daemon").format(self, ctx, lines, callback)
          end
        '';
        condition = lib.mkLuaInline ''
          function()
            return require("csharpier-daemon").available()
          end
        '';
      };

      luaConfigRC.csharpier-daemon = builtins.readFile ./csharpier.lua;

      augroups = [{name = "CsharpierDaemon";} {name = "CSharpIndent";}];
      autocmds = [
        {
          event = ["FileType"];
          pattern = ["cs"];
          desc = "Start the csharpier server before the first save needs it";
          group = "CsharpierDaemon";
          callback = lib.mkLuaInline ''
            function()
              require("csharpier-daemon").start()
            end
          '';
        }
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
          setupOpts.extensions.razor.enabled = false;
          setupOpts.silent = true;
        };
      };

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

      extraPackages = [pkgs.netcoredbg pkgs.dotnet-sdk_10];

      augroups = [{name = "RoslynFidget";}];
      autocmds = [
        {
          event = ["User"];
          pattern = ["RoslynOnInit"];
          desc = "Report roslyn initialization through fidget, replacing the silenced notify";
          group = "RoslynFidget";
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
