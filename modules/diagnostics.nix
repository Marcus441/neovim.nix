{
  flake.modules.nvf.core = {lib, ...}: let
    icons = ''
      {
        [vim.diagnostic.severity.ERROR] = "󰅚 ",
        [vim.diagnostic.severity.WARN] = "󰀪 ",
        [vim.diagnostic.severity.INFO] = "󰋽 ",
        [vim.diagnostic.severity.HINT] = "󰌶 ",
      }
    '';
  in {
    vim.diagnostics = {
      enable = true;
      config = {
        underline = true;
        severity_sort = true;
        signs = false;
        virtual_text = {
          spacing = 4;
          source = "if_many";
          prefix = lib.generators.mkLuaInline ''
            function(diagnostic)
              local icons = ${icons}
              return icons[diagnostic.severity]
            end
          '';
        };
        # load-bearing: docs/decisions/theme.md#picker-blocks
        float = {
          border = "solid";
          header = "";
          source = true;
          max_width = 100;
        };
      };
    };

    vim.keymaps = [
      {
        mode = ["n"];
        key = "<leader>e";
        lua = true;
        action = ''
          function()
            local _, winid = vim.diagnostic.open_float()
            if winid then
              vim.wo[winid].winhighlight =
                "NormalFloat:DiagnosticFloat,FloatBorder:DiagnosticFloatBorder"
            end
          end
        '';
        desc = "[E]xpand diagnostic";
      }
    ];
  };
}
