{
  flake.modules.nvf.core = {
    vim.autocmds = [
      {
        event = [ "TextYankPost" ];
        desc = "Highlight yanked text";
        command = "lua vim.hl.on_yank()";
      }
    ];
  };
}
