{
  flake.modules.nvf.core = {
    vim.autocmds = [
      {
        event = [ "FileType" ];
        pattern = [
          "gitcommit"
          "markdown"
          "text"
        ];
        desc = "Enable spellcheck for prose";
        command = "setlocal spell";
      }
    ];
  };
}
