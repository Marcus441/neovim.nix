{ config, ... }:
let
  inherit (config.flake.lib) preferPathExe;
in
{
  flake.modules.nvf.core = { lib, ... }: {
    vim = {
      languages.nix = {
        enable = true;
        format.type = [ "nixfmt" ];
        lsp.enable = lib.mkDefault false;
      };

      formatter.conform-nvim.setupOpts.formatters.nixfmt.command = lib.mkForce "nixfmt";
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
      inherit (lib.nvim.dag) entryBefore;

      nixdExe = preferPathExe pkgs "nixd" (lib.getExe pkgs.nixd);
    in
    {
      vim = {
        formatter.conform-nvim.setupOpts.formatters.nixfmt.command = lib.mkOverride 40 (
          preferPathExe pkgs "nixfmt" (lib.getExe pkgs.nixfmt)
        );

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
            cmd = lib.mkForce (mkLuaInline ''
              function(dispatchers, config)
                local devenv = _NIXD_DEVENV_ROOT(config.root_dir)
                if devenv then
                  return vim.lsp.rpc.start({"devenv", "lsp"}, dispatchers, {cwd = devenv})
                end
                return vim.lsp.rpc.start({"${nixdExe}"}, dispatchers)
              end
            '');

            before_init = mkLuaInline ''
              function(_, config)
                if config.settings and _NIXD_DEVENV_ROOT(config.root_dir) then
                  for key in pairs(config.settings) do
                    config.settings[key] = nil
                  end
                end
              end
            '';

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

        luaConfigRC.nixd-devenv = entryBefore [ "lsp-servers" ] ''
          _NIXD_DEVENV_ROOT = function(source)
            if source == nil or source == "" then
              source = vim.uv.cwd()
            end

            local found, root = pcall(vim.fs.root, source, "devenv.nix")
            if not found or not root then
              return nil
            end

            if vim.fn.executable("devenv") ~= 1 then
              if not _NIXD_DEVENV_REPORTED then
                _NIXD_DEVENV_REPORTED = true
                vim.notify("[nixd] " .. root .. " is a devenv project but devenv is not on PATH; "
                  .. "falling back to the system flake", vim.log.levels.WARN)
              end
              return nil
            end

            return root
          end
        '';
      };
    };
}
