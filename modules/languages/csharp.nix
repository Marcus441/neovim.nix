{
  flake.modules.nvf.core = {lib, ...}: {
    vim = {
      languages.csharp = {
        enable = true;
        treesitter.enable = true;
        format.type = ["csharpier"];
        lsp.enable = lib.mkDefault false;
      };

      augroups = [{name = "CSharpIndent";}];
      autocmds = [
        {
          event = ["FileType"];
          pattern = ["cs"];
          desc = "Use smartindent for C# since treesitter has no indent queries";
          group = "CSharpIndent";
          callback = lib.mkLuaInline ''
            function()
              vim.bo.indentexpr = ""
              vim.bo.smartindent = true
            end
          '';
        }
      ];
    };
  };

  flake.modules.nvf.gui = {
    vim.languages.csharp = {
      lsp = {
        enable = true;
        servers = ["roslyn-ls"];
      };
      extensions.roslyn-nvim = {
        enable = true;
        setupOpts.filewatching = "roslyn";
        setupOpts.extensions.razor.enabled = true;
      };
    };
  };
}
