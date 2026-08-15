{
  flake.modules.nvf.core = {lib, ...}: {
    # load-bearing: docs/decisions/split-navigation.md#multiplexer-detection
    vim.globals.smart_splits_multiplexer_integration = lib.mkLuaInline ''(vim.env.TMUX ~= nil and "tmux") or nil'';

    vim.utility.smart-splits = {
      enable = true;
      # load-bearing: docs/decisions/split-navigation.md#the-edge-behaviour-is-stop-because-kitty-cannot-wrap
      setupOpts.at_edge = "stop";
      # load-bearing: docs/decisions/split-navigation.md#the-swap-binds-shadow-the-buffer-picker
      keymaps = {
        swap_buf_left = null;
        swap_buf_down = null;
        swap_buf_up = null;
        swap_buf_right = null;
      };
    };
  };
}
