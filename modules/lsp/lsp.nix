{
  flake.modules.nvf.dev = {
    vim = {
      startPlugins = [ "nvim-lspconfig" ];

      keymaps = [
        {
          mode = [ "n" ];
          key = "gd";
          action = "<cmd>lua Snacks.picker.lsp_definitions()<cr>";
          desc = "[G]oto [D]efinition";
        }
        {
          mode = [ "n" ];
          key = "gD";
          action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
          desc = "[G]oto [D]eclaration";
        }
        {
          mode = [ "n" ];
          key = "grr";
          action = "<cmd>lua Snacks.picker.lsp_references()<cr>";
          desc = "[G]oto [R]eferences";
        }
        {
          mode = [ "n" ];
          key = "gri";
          action = "<cmd>lua Snacks.picker.lsp_implementations()<cr>";
          desc = "[G]oto [I]mplementation";
        }
        {
          mode = [ "n" ];
          key = "grt";
          action = "<cmd>lua Snacks.picker.lsp_type_definitions()<cr>";
          desc = "[G]oto [T]ype definition";
        }
        {
          mode = [ "n" ];
          key = "gO";
          action = "<cmd>lua Snacks.picker.lsp_symbols()<cr>";
          desc = "Document symbols";
        }
        {
          mode = [ "n" ];
          key = "gW";
          action = "<cmd>lua Snacks.picker.lsp_workspace_symbols()<cr>";
          desc = "Workspace symbols";
        }
      ];
    };
  };
}
