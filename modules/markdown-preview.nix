{
  flake.modules.nvf.dev = {pkgs, ...}: {
    vim = {
      utility.preview.markdownPreview.enable = true;

      # load-bearing: docs/decisions/markdown.md#the-preview-needs-node-on-path
      extraPackages = [pkgs.nodejs];

      keymaps = [
        {
          mode = ["n"];
          key = "<leader>mp";
          action = "<CMD>MarkdownPreviewToggle<CR>";
          desc = "[M]arkdown [P]review";
        }
      ];
    };
  };
}
