{lib, ...}: {
  vim = {
    augroups = [
      {name = "UserSetup";}
      {name = "SpellCheck";}
    ];
    autocmds = [
      {
        event = ["TextYankPost"];
        desc = "Highlight when yanking (copying) text";
        group = "UserSetup";
        callback = lib.mkLuaInline ''
          function()
            vim.hl.on_yank()
          end
        '';
      }
      {
        event = ["FileType"];
        pattern = ["markdown"];
        desc = "Enable spellcheck for markdown";
        group = "SpellCheck";
        callback = lib.mkLuaInline ''
          function()
            vim.opt_local.spell = true
            vim.opt_local.spelllang = "en"
          end
        '';
      }
    ];
  };
}
