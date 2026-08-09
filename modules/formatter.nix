{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          format_on_save = {};
          # load-bearing: docs/decisions/formatters.md#path-resolution
          formatters = {
            rustfmt.command = lib.mkForce "rustfmt";
            clang-format.command = lib.mkForce "clang-format";
          };
        };
      };
    };
  };
}
