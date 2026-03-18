let
  general = import ./general.nix;
  lsp = import ./lsp.nix;
  oil = import ./oil.nix;
  neogen = import ./neogen.nix;
  telescope = import ./telescope.nix;
  trouble = import ./trouble.nix;
in {
  programs.nvf.settings.vim.keymaps =
    lsp
    ++ oil
    ++ neogen
    ++ telescope
    ++ trouble
    ++ general;
}
