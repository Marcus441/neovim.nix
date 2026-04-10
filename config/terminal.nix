{pkgs, ...}: {
  vim.terminal.toggleterm = {
    enable = true;

    mappings.open = "<A-t>";

    lazygit = {
      enable = true;
      direction = "float";
      mappings.open = "<leader>gg"; # Space + g + g
    };

    setupOpts = {
      direction = "float";

      float_opts = {
        border = "rounded";
        winblend = 0;
      };

      size = {
        _type = "lua-inline";
        expr = ''
          function(term)
            if term.direction == "horizontal" then
              return 15
            elseif term.direction == "vertical" then
              return vim.o.columns * 0.4
            end
          end
        '';
      };
    };
  };
}
