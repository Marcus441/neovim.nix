{config, ...}: let
  inherit (config.flake.lib) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          format_on_save = lib.mkLuaInline ''
            function(bufnr)
              if vim.g.disable_autoformat then
                return
              end
              if vim.bo[bufnr].filetype == "cs" then
                return { timeout_ms = 3000 }
              end
              return {}
            end
          '';
          format_after_save = null;
          formatters.prettier = {
            command = lib.mkForce "prettierd";
            args = lib.mkForce ["$FILENAME"];
          };
        };
      };

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
    vim.formatter.conform-nvim.setupOpts.formatters.prettier.command =
      lib.mkOverride 40
      (preferPathExe pkgs "prettierd" (lib.getExe pkgs.prettierd));
  };
}
