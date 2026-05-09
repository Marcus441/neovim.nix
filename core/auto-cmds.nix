{lib, ...}: {
  vim = {
    augroups = [
      {name = "UserSetup";}
      {name = "SpellCheck";}
      {name = "CSharpIndent";}
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
      {
        event = ["FileType"];
        pattern = ["cs"];
        desc = "Use smartindent for C# since treesitter has no indent queries";
        group = "CSharpIndent";
        callback = lib.mkLuaInline ''
          function()
            vim.bo.indentexpr = ""
            vim.bo.smartindent = true
          end
        '';
      }
    ];
  };
}
