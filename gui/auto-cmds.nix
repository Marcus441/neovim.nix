{lib, ...}: {
  vim = {
    augroups = [
      {name = "MacroRecordingNotificationGroup";}
    ];
    autocmds = [
      {
        event = ["RecordingEnter"];
        desc = "Notify when macro recording starts";
        group = "MacroRecordingNotificationGroup";
        callback = lib.mkLuaInline ''
          function()
            local msg = string.format("Register: %s", vim.fn.reg_recording())
            _MACRO_RECORDING_STATUS = true
            vim.notify(msg, vim.log.levels.INFO, {
              title = "Macro Recording",
              -- The `keep` function is embedded directly within the Lua string
              keep = function() return _MACRO_RECORDING_STATUS end,
            })
          end
        '';
      }
      {
        event = ["RecordingLeave"];
        desc = "Notify when macro recording ends";
        group = "MacroRecordingNotificationGroup";
        callback = lib.mkLuaInline ''
          function()
            _MACRO_RECORDING_STATUS = false
            vim.notify("Success!", vim.log.levels.INFO, {
              title = "Macro Recording End",
              timeout = 2000,
            })
          end
        '';
      }
    ];
  };
}
