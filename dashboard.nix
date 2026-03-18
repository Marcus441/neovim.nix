{lib, ...}: let
  header = [
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

  mkButton = shortcut: icon: text: command: {
    type = "button";
    val = "${icon}  ${text}";
    on_press = lib.mkLuaInline ''
      function()
        vim.cmd[[${command}]]
      end
    '';
    opts = {
      inherit shortcut;
      keymap = [
        "n"
        shortcut
        ":${command}<CR>"
        {
          noremap = true;
          silent = true;
          nowait = true;
        }
      ];
      position = "center";
      cursor = 5;
      width = 50;
      align_shortcut = "right";
    };
  };
in {
  vim = {
    dashboard.alpha = {
      enable = true;
      theme = null;

      layout = [
        # --- 1. TOP PADDING ---
        {
          type = "padding";
          val = 8;
        }

        # --- 2. HEADER (Applying the custom color) ---
        {
          type = "text";
          val = header;
          opts = {
            position = "center";
            # Use the custom highlight group defined above
            hl = "DashboardHeader";
          };
        }

        # --- 3. SEPARATOR PADDING ---
        {
          type = "padding";
          val = 2;
        }

        # --- 4. BUTTONS ---
        {
          type = "group";
          val = [
            (mkButton "e" "" "> New file" "ene | startinsert")
            (mkButton "f" "" "> Find file" "Telescope find_files")
            (mkButton "g" "" "> Live Grep" "Telescope live_grep")
            (mkButton "r" "" "> Recent" "Telescope oldfiles")
            (mkButton "l" "" "> Last session" "SessionManager load_last_session")
            (mkButton "s" "" "> Settings" "e $HOME/flake | :cd %:p:h | split . | wincmd k | pwd")
            (mkButton "q" "" "> Quit NVIM" "qa")
          ];
          opts = {
            spacing = 0;
          };
        }
      ];
    };
  };
}
