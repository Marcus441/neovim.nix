{pkgs, ...}: {
  vim.extraPlugins = {
    theme-plugin = {
      package = pkgs.vimPlugins.kanagawa-nvim;
      setup = builtins.readFile ./lua/kanagawa-setup.lua;
    };
    vim-tmux-navigator = {
      package = pkgs.vimPlugins.vim-tmux-navigator;
      setup = "
          vim.g.tmux_navigator_no_mappings = 1
          vim.g.tmux_navigator_no_wrap = 1
          ";
    };
    undotree = {
      package = pkgs.vimPlugins.undotree;
      setup = "";
      after = ["vim-tmux-navigator"];
    };
    neogen = {
      package = pkgs.vimPlugins.neogen;
      setup = ''
        require('neogen').setup({
          enabled = true,
          snippet_engine = "luasnip",
          languages = {
            cs = {
              template = {
                annotation_convention = "xmldoc" -- This forces the XML style
              }
            }
          }
        })
      '';
    };
  };
}
