{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          format_on_save = {};
          formatters = {
            rustfmt.command = lib.mkForce "rustfmt";
            clang-format.command = lib.mkForce "clang-format";
          };
        };
      };
    };
  };
}
