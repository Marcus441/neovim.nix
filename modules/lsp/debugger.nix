{
  flake.modules.nvf.dev =
    { lib, ... }:
    {
      vim.debugger.nvim-dap = {
        enable = true;
        ui.enable = true;

        mappings =
          lib.genAttrs [
            "goDown"
            "goUp"
            "hover"
            "restart"
            "runLast"
            "runToCursor"
            "stepBack"
            "terminate"
            "toggleDapUI"
            "toggleRepl"
          ] (_: null)
          // {
            continue = "<F5>";
            stepOver = "<F10>";
            stepInto = "<F11>";
            stepOut = "<F12>";
            toggleBreakpoint = "<leader>b";
          };
      };
    };
}
