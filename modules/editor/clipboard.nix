{
  flake.modules.nvf.core =
    {
      pkgs,
      lib,
      ...
    }:
    {
      vim.clipboard = {
        enable = true;
        registers = "unnamedplus";
        providers = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          wl-copy.enable = true;
          xsel.enable = true;
        };
      };

      vim.keymaps = [
        {
          mode = [
            "n"
            "v"
          ];
          key = "<leader>d";
          action = "\"_d";
          desc = "Delete to void register";
        }
      ];
    };
}
