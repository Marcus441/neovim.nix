{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        myNeovim =
          (nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [
              ./autoCmds.nix
              ./autoComplete.nix
              ./dashboard.nix
              ./debugger.nix
              ./extraPlugins.nix
              ./formatter.nix
              ./keymaps
              ./languages.nix
              ./lsp.nix
              ./sessions.nix
              ./terminal.nix
              {
                config.vim = {
                  vimAlias = true;
                  undoFile.enable = true;
                  lineNumberMode = "relNumber";
                  enableLuaLoader = true;
                  preventJunkFiles = true;
                  telescope = {
                    enable = true;
                    setupOpts.defaults.color_devicons = true;
                  };
                  treesitter = {
                    context.enable = false;
                    indent.enable = false;
                  };
                  options = {
                    guicursor = "i:block";
                    tabstop = 4;
                    shiftwidth = 2;
                    smartindent = true;
                    wrap = true;
                  };

                  clipboard = {
                    enable = true;
                    registers = "unnamedplus";
                    providers = {
                      wl-copy.enable = true;
                      xsel.enable = true;
                    };
                  };

                  diagnostics = {
                    enable = true;
                    config = {
                      signs = true;
                      underline = true;
                      update_in_insert = false;
                      virtual_lines = {
                        current_line = true;
                        severity = {
                          min = "ERROR";
                        };
                      };
                      virtual_text = {
                        severity = {
                          min = "INFO";
                          max = "WARN";
                        };
                      };
                    };
                  };

                  spellcheck = {
                    enable = true;
                    languages = ["en"];
                    programmingWordlist.enable = true;
                  };

                  visuals = {
                    nvim-web-devicons.enable = true;
                    nvim-cursorline.enable = true;
                    cinnamon-nvim.enable = true;
                    fidget-nvim = {
                      enable = true;
                      setupOpts = {
                        notification.window.winblend = 0;
                        progress = {
                          display = {
                            done_icon = "✓";
                          };
                        };
                      };
                    };
                    highlight-undo.enable = true;
                    indent-blankline = {
                      enable = true;
                      setupOpts = {
                        exclude = {
                          filetypes = ["alpha"];
                        };
                        scope = {
                          enabled = true;
                        };
                      };
                    };
                    rainbow-delimiters.enable = false;
                  };

                  autopairs.nvim-autopairs.enable = true;

                  snippets = {
                    luasnip.enable = true;
                    luasnip.loaders = "require('luasnip.loaders.from_vscode').lazy_load()";
                  };

                  binds = {
                    whichKey = {
                      enable = true;
                      register = {
                        "<leader>c" = "[C]ode";
                        "<leader>d" = "[D]ocument";
                        "<leader>r" = "[R]ename";
                        "<leader>s" = "[S]earch";
                        "<leader>w" = "[W]orkspace";
                        "<leader>t" = "[T]oggle";
                        "<leader>h" = "Git [H]unk";
                      };
                    };
                    cheatsheet.enable = true;
                  };

                  git = {
                    enable = true;
                    gitsigns.enable = true;
                    gitsigns.codeActions.enable = false;
                  };

                  projects.project-nvim.enable = true;

                  statusline.lualine.enable = true;
                  mini = {
                    icons.enable = true;
                    ai.enable = true;
                    snippets.enable = true;
                    surround.enable = true;
                    indentscope = {
                      enable = true;
                      setupOpts = {
                        ignore_filetypes = [
                          "NvimTree"
                          "TelescopePrompt"
                          "help"
                          "neo-tree"
                          "notify"
                          "alpha"
                          "snacks_notif"
                          "snacks_notif_history"
                        ];
                        symbol = "┃";
                        draw = {
                          delay = 0;
                          animation = lib.mkLuaInline ''require('mini.indentscope').gen_animation.none()'';
                        };
                      };
                    };
                  };

                  utility = {
                    ccc.enable = false;
                    diffview-nvim.enable = true;
                    direnv.enable = true;
                    icon-picker.enable = true;
                    motion = {precognition.enable = false;};
                    oil-nvim.enable = true;
                    snacks-nvim = {
                      enable = true;
                      setupOpts = {
                        image = {
                          enabled = true;
                        };
                        notifier = {
                          enabled = true;
                          timeout = 3000;
                          style = "fancy";
                        };
                      };
                    };
                    surround.enable = true;
                    vim-wakatime.enable = false;
                  };

                  ui = {
                    borders.enable = true;
                    noice = {
                      enable = true;
                      setupOpts.lsp.signature.enabled = true;
                    };
                    colorizer = {
                      enable = true;
                      setupOpts = {
                        filetypes = {
                          "*" = {
                            RGB = true;
                            RRGGBB = true;
                            always_update = true;
                            css = true;
                            mode = "background";
                          };
                        };
                      };
                    };

                    illuminate.enable = true;
                    breadcrumbs = {
                      enable = false;
                      navbuddy.enable = false;
                    };
                    smartcolumn = {
                      enable = true;
                      setupOpts.disabled_filetypes = [
                        "help"
                        "text"
                        "markdown"
                        "NvimTree"
                        "alpha"
                      ];
                    };
                    fastaction.enable = true;
                  };

                  notes.todo-comments.enable = true;
                  comments = {
                    comment-nvim.enable = true;
                  };
                };
              }
            ];
          }).neovim;
      in {
        packages.default = myNeovim;

        packages.nvim = myNeovim;
      }
    );
}
