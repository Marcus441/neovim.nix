{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      languages.nix = {
        enable = true;
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters_by_ft.nix = [ "nixfmt" ];
    };
  };

  flake.modules.nvf.dev =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkLuaInline;
    in
    {
      vim = {
        diagnostics.nvim-lint.linters_by_ft.nix = [
          "statix"
          "deadnix"
        ];

        extraPackages = [
          pkgs.deadnix
          pkgs.nixfmt
          pkgs.statix
        ];

        languages.nix.lsp = {
          enable = true;
          servers = [
            "nil"
            "nixd"
          ];
        };

        lsp.servers = {
          nil = {
            cmd = lib.mkForce [
              (preferPathExe pkgs "nil" (lib.getExe pkgs.nil))
            ];

            on_attach = mkLuaInline ''
              function(client, _)
                client.server_capabilities.completionProvider = nil
              end
            '';
          };

          nixd = {
            cmd = lib.mkForce [
              (preferPathExe pkgs "nixd" (lib.getExe pkgs.nixd))
            ];

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
      };
    };
}
