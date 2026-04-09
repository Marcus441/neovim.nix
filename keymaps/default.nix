let
  general = import ./general.nix;
  lsp = import ./lsp.nix;
  oil = import ./oil.nix;
  neogen = import ./neogen.nix;
  snacks_picker = import ./snacks_picker.nix;
  trouble = import ./trouble.nix;
in {
  vim.keymaps =
    lsp
    ++ oil
    ++ neogen
    ++ snacks_picker
    ++ trouble
    ++ general;
}
