{
  flake.modules.nvf.dev = {
    vim.utility.snacks-nvim.setupOpts.indent = {
      enabled = true;
      indent.char = "│";
      scope = {
        enabled = true;
        char = "┃";
      };
      chunk = {
        enabled = true;
        char = {
          corner_top = "╭";
          corner_bottom = "╰";
          horizontal = "─";
          vertical = "│";
          arrow = "─";
        };
      };
    };
  };
}
