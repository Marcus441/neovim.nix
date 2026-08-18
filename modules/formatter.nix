{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          format_on_save = {};
          # load-bearing: docs/decisions/formatters.md#path-resolution
          formatters = {
            alejandra.command = lib.mkForce "alejandra";
            clang-format.command = lib.mkForce "clang-format";
            prettier.command = lib.mkForce "prettier";
            ruff.command = lib.mkForce "ruff";
            rustfmt.command = lib.mkForce "rustfmt";
            stylua.command = lib.mkForce "stylua";
          };
        };
      };
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
