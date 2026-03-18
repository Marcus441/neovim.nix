[
  {
    mode = ["n"];
    key = "gd";
    action = "<cmd>Telescope lsp_definitions<cr>";
    desc = "[G]oto [D]efinition";
  }
  {
    mode = ["n"];
    key = "gr";
    action = "<cmd>Telescope lsp_references<cr>";
    desc = "[G]oto [R]eferences";
  }
  {
    mode = ["n"];
    key = "gI";
    action = "<cmd>Telescope lsp_implementations<cr>";
    desc = "[G]oto [I]mplementation";
  }
  {
    mode = ["n"];
    key = "<leader>D";
    action = "<cmd>Telescope lsp_type_definitions<cr>";
    desc = "Type [D]efinition";
  }
  {
    mode = ["n"];
    key = "<leader>ds";
    action = "<cmd>Telescope lsp_document_symbols<cr>";
    desc = "[D]ocument [S]ymbols";
  }
  {
    mode = ["n"];
    key = "<leader>ws";
    action = "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>";
    desc = "[W]orkspace [S]ymbols";
  }
  {
    mode = ["n"];
    key = "<leader>rn";
    action = "<cmd>lua vim.lsp.buf.rename()<cr>";
    desc = "[R]e[n]ame";
  }
  {
    mode = ["n"];
    key = "<leader>ca";
    action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
    desc = "[C]ode [A]ction";
  }
  {
    mode = ["n"];
    key = "gD";
    action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
    desc = "[G]oto [D]eclaration";
  }
]
