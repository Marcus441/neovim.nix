{
  flake.modules.nvf.core = {pkgs, ...}: {
    vim = {
      undoFile.enable = true;
      visuals.highlight-undo.enable = true;

      extraPlugins.undotree = {
        package = pkgs.vimPlugins.undotree;
        after = ["theme-plugin"];
      };

      keymaps = [
        {
          mode = ["n"];
          key = "<leader>u";
          action = "<CMD>UndotreeToggle<CR>";
          desc = "[U]ndotree";
        }
      ];
    };
  };
}
