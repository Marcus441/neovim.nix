{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          # load-bearing: docs/decisions/formatters.md#format-on-save-gates-on-a-global
          format_on_save = lib.mkLuaInline ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.bo[bufnr].filetype == "cs" then
                return
              end
              return {}
            end
          '';
          # load-bearing: docs/decisions/formatters.md#format-on-save-gates-on-a-global
          format_after_save = lib.mkLuaInline ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.bo[bufnr].filetype ~= "cs" then
                return
              end
              return {}
            end
          '';
          # load-bearing: docs/decisions/formatters.md#path-resolution
          formatters = {
            alejandra.command = lib.mkForce "alejandra";
            clang-format.command = lib.mkForce "clang-format";
            # load-bearing: docs/decisions/csharp.md#csharpier-formats-roslyn-is-the-fallback
            csharpier = {
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
            prettier.command = lib.mkForce "prettier";
            ruff.command = lib.mkForce "ruff";
            rustfmt.command = lib.mkForce "rustfmt";
            stylua.command = lib.mkForce "stylua";
          };
        };
      };

      luaConfigRC.csharpier-daemon = builtins.readFile ./csharpier-daemon.lua;

      augroups = [{name = "CsharpierDaemon";}];
      autocmds = [
        {
          event = ["FileType"];
          pattern = ["cs"];
          desc = "Start the csharpier server before the first save needs it";
          group = "CsharpierDaemon";
          # load-bearing: docs/decisions/csharp.md#csharpier-formats-roslyn-is-the-fallback
          callback = lib.mkLuaInline ''
            function()
              require("csharpier-daemon").start()
            end
          '';
        }
      ];

      keymaps = [
        {
          mode = ["n"];
          key = "<leader>tf";
          action = "function() vim.g.disable_autoformat = not vim.g.disable_autoformat; vim.notify(\"Format on save \" .. (vim.g.disable_autoformat and \"disabled\" or \"enabled\")) end";
          lua = true;
          desc = "[T]oggle [F]ormat on save";
        }
      ];
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: {
    # load-bearing: docs/conventions/overrides.md#a-formatter-command-needs-mkoverride-40
    vim.formatter.conform-nvim.setupOpts.formatters = {
      alejandra.command =
        lib.mkOverride 40
        (preferPathExe pkgs "alejandra" (lib.getExe pkgs.alejandra));

      clang-format.command =
        lib.mkOverride 40
        (preferPathExe pkgs "clang-format" (lib.getExe' pkgs.clang-tools "clang-format"));

      prettier.command =
        lib.mkOverride 40
        (preferPathExe pkgs "prettier" (lib.getExe pkgs.prettier));

      ruff.command =
        lib.mkOverride 40
        (preferPathExe pkgs "ruff" (lib.getExe pkgs.ruff));

      stylua.command =
        lib.mkOverride 40
        (preferPathExe pkgs "stylua" (lib.getExe pkgs.stylua));
    };
  };
}
