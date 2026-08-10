{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.nix = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    pkgs,
    lib,
    ...
  }: let
    inherit (lib.generators) mkLuaInline;
  in {
    vim = {
      languages.nix.lsp = {
        enable = true;
        servers = ["nil" "nixd"];
      };

      # load-bearing: docs/decisions/nix-lsp-split.md#capability-partition
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

          # load-bearing: docs/decisions/nix-lsp-split.md#nixd-evaluates-the-system-flake
          settings = mkLuaInline ''
            (function()
              local getFlake = '(builtins.getFlake "' .. vim.env.HOME .. '/.dotfiles/flake")'
              local host = vim.fn.hostname()
              return {
                nixd = {
                  nixpkgs = {expr = "import " .. getFlake .. ".inputs.nixpkgs { }"},
                  formatting = {command = {"alejandra"}},
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
