{
  flake.modules.nvf.dev = {lib, ...}: {
    vim = {
      utility.direnv.enable = true;

      globals.direnv_silent_load = 1;

      # load-bearing: docs/decisions/direnv.md#its-own-group
      luaConfigRC.direnv = builtins.readFile ./direnv.lua;

      augroups = [{name = "DirenvFidget";}];

      autocmds = [
        # load-bearing: docs/decisions/direnv.md#the-stderr-sink
        {
          event = ["VimEnter"];
          desc = "Divert direnv.vim's stderr from its script-local dict into _DIRENV";
          group = "DirenvFidget";
          callback = lib.mkLuaInline ''
            function()
              vim.cmd([[
                function! direnv#on_stderr(_, data, ...) abort
                  call v:lua._DIRENV.on_stderr(a:data)
                endfunction
              ]])
            end
          '';
        }
        # load-bearing: docs/decisions/direnv.md#the-spinner
        {
          event = ["VimEnter" "DirChanged"];
          desc = "Track an export; a spinner opens only if it is still running 700 ms in";
          group = "DirenvFidget";
          callback = lib.mkLuaInline "function() _DIRENV.start() end";
        }
        {
          event = ["User"];
          pattern = ["DirenvLoaded"];
          desc = "Close the export's item with a one-line summary once its stderr hit EOF";
          group = "DirenvFidget";
          callback = lib.mkLuaInline "function() _DIRENV.loaded() end";
        }
      ];
    };
  };
}
