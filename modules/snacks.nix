{
  flake.modules.nvf.core = {
    vim.utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        bigfile.enabled = true;
        picker = {
          enabled = true;
          sources.zoxide = {};
          sources.projects = {
            dev = ["~/Projects" "~/projects" "~/oss"];
            patterns = [".git" "flake.nix" "package.json" "Makefile"];
          };
        };
        input.enabled = true;
        quickfile.enabled = true;
        scope.enabled = true;
        statuscolumn.enabled = true;
      };
    };
  };

  flake.modules.nvf.gui = {
    vim.utility.snacks-nvim.setupOpts = {
      dim.enabled = true;
      gitbrowse.enabled = true;
      indent = {
        enabled = true;
        indent.char = "│";
        scope = {
          enabled = true;
          char = "┃";
        };
        chunk = {
          enabled = true;
          char = {
            corner_top = "╭";
            corner_bottom = "╰";
            horizontal = "─";
            vertical = "│";
            arrow = "─";
          };
        };
      };
      lazygit.enabled = true;
      notifier = {
        enabled = true;
        timeout = 3000;
        style = "fancy";
      };
      rename.enabled = true;
      scratch.enabled = true;
      words.enabled = true;
      zen.enabled = true;
    };
  };
}
