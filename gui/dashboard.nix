{lib, ...}: {
  vim.utility.snacks-nvim.setupOpts.dashboard = {
    enabled = true;
    sections = [
      {section = "header";}
      {
        section = "keys";
        gap = 1;
        padding = 1;
      }
    ];
    preset = {
      header = lib.concatStringsSep "\n" [
        "                                                                       "
        "                                                                     "
        "       ████ ██████           █████      ██                     "
        "      ███████████             █████                             "
        "      █████████ ███████████████████ ███   ███████████   "
        "     █████████  ███    █████████████ █████ ██████████████   "
        "    █████████ ██████████ █████████ █████ █████ ████ █████   "
        "  ███████████ ███    ███ █████████ █████ █████ ████ █████  "
        " ██████  █████████████████████ ████ █████ █████ ████ ██████ "
      ];
      keys = [
        {
          action = ":ene | startinsert";
          icon = " ";
          key = "e";
          desc = "New file";
        }
        {
          action = ":lua Snacks.picker.files()";
          icon = " ";
          key = "f";
          desc = "Find file";
        }
        {
          action = ":lua Snacks.picker.grep()";
          icon = " ";
          key = "g";
          desc = "Live Grep";
        }
        {
          action = ":lua Snacks.picker.recent()";
          icon = " ";
          key = "r";
          desc = "Recent";
        }
        {
          action = ":lua Snacks.picker.projects()";
          icon = " ";
          key = "p";
          desc = "Projects";
        }
        {
          action = ":SessionManager load_last_session";
          icon = " ";
          key = "l";
          desc = "Last session";
        }
        {
          action = ":qa";
          icon = " ";
          key = "q";
          desc = "Quit";
        }
      ];
    };
  };
}
