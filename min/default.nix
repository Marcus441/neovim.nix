{lib, ...}: {
  vim = {
    mini.statusline.enable = true;
    treesitter.enable = true;

    # Resolve toolchain-sized formatters from $PATH (dev shell / direnv)
    # instead of pinning them: rustfmt pulls rustc+cargo (~2.4 GB) and
    # clang-format pulls clang (~2.1 GB) into the closure.
    formatter.conform-nvim.setupOpts.formatters = {
      rustfmt.command = lib.mkForce "rustfmt";
      clang-format.command = lib.mkForce "clang-format";
    };
  };
}
