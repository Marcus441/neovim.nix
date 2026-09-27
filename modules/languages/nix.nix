{
  flake.modules.nvf.core = {
    vim = {
      languages.nix.enable = true;
      formatter.conform-nvim.setupOpts.formatters_by_ft.nix = [ "nixfmt" ];
    };
  };

  flake.modules.nvf.dev =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkLuaInline;
    in
    {
      vim = {
        lsp.servers = {
          nil_ls.on_attach = mkLuaInline ''
            function(client, _)
              client.server_capabilities.completionProvider = nil
            end
          '';

          nixd = {
            on_attach = mkLuaInline ''
              function(client, _)
                client.server_capabilities = {
                  completionProvider = client.server_capabilities.completionProvider,
                  positionEncoding = client.server_capabilities.positionEncoding,
                  textDocumentSync = client.server_capabilities.textDocumentSync,
                }
              end
            '';

            handlers = {
              "textDocument/publishDiagnostics" = mkLuaInline "function() end";
            };

            settings = mkLuaInline ''
              (function()
                local getFlake = '(builtins.getFlake "' .. vim.env.HOME .. '/.dotfiles/flake")'
                local host = vim.fn.hostname()
                return {
                  nixd = {
                    nixpkgs = {expr = "import " .. getFlake .. ".inputs.nixpkgs { }"},
                    options = {
                      nixos = {expr = getFlake .. '.nixosConfigurations."' .. host .. '".options'},
                      home_manager = {
                        expr = getFlake .. '.homeConfigurations."' .. vim.env.USER .. "@" .. host .. '".options',
                      },
                    },
                  },
                }
              end)()
            '';
          };
        };

        diagnostics.nvim-lint.linters_by_ft.nix = [
          "statix"
          "deadnix"
        ];

        extraPackages = [
          pkgs.deadnix
          pkgs.nil
          pkgs.nixd
          pkgs.nixfmt
          pkgs.statix
        ];
      };
    };
}
