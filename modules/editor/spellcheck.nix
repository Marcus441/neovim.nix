{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      augroups = [{name = "SpellCheck";}];
      autocmds = [
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
  };

  flake.modules.nvf.dev = {
    vim.spellcheck = {
      enable = true;
      languages = ["en"];
      programmingWordlist.enable = false;
    };
  };
}
