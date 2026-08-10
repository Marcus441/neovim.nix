{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      augroups = [{name = "UserSetup";}];
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
      ];
    };
  };
}
