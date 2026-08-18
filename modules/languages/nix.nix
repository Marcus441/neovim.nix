{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.nix = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.dev = {
    pkgs,
    lib,
    ...
  }: let
    inherit (lib) mkLuaInline;
    inherit (lib.nvim.dag) entryBefore;

    nixdExe = preferPathExe pkgs "nixd" (lib.getExe pkgs.nixd);
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
          # load-bearing: docs/decisions/nix-lsp-split.md#devenv-owns-its-own-nixd
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

          # load-bearing: docs/decisions/nix-lsp-split.md#nixd-evaluates-the-system-flake
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

      # load-bearing: docs/decisions/nix-lsp-split.md#devenv-owns-its-own-nixd
      luaConfigRC.nixd-devenv = entryBefore ["lsp-servers"] ''
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

      augroups = [{name = "NixdFlakeCheck";}];

      autocmds = [
        # load-bearing: docs/decisions/nix-lsp-split.md#reporting-the-precondition
        {
          event = ["FileType"];
          pattern = ["nix"];
          desc = "Report once whether the flake nixd is pointed at can answer for this host";
          group = "NixdFlakeCheck";
          callback = mkLuaInline ''
            function(event)
              if _NIXD_FLAKE_CHECKED or _NIXD_DEVENV_ROOT(event.buf) then
                return
              end
              _NIXD_FLAKE_CHECKED = true

              local flake = vim.env.HOME .. "/.dotfiles/flake"
              local host = vim.fn.hostname()
              local account = vim.env.USER .. "@" .. host

              local function warn(what)
                vim.notify("[nixd] " .. what .. "; flake-derived completion is missing",
                  vim.log.levels.WARN)
              end

              local function report(out)
                if out.code ~= 0 then
                  warn(flake .. " did not evaluate")
                  return
                end
                local ok, names = pcall(vim.json.decode, out.stdout)
                if not ok then
                  warn(flake .. " named no configurations")
                  return
                end
                if not vim.tbl_contains(names.nixos, host) then
                  warn("nixosConfigurations has no " .. host)
                end
                if not vim.tbl_contains(names.home, account) then
                  warn("homeConfigurations has no " .. account)
                end
              end

              if not vim.uv.fs_stat(flake .. "/flake.nix") then
                warn("no flake at " .. flake)
                return
              end
              local expr = "let f = builtins.getFlake " .. vim.fn.json_encode(flake)
                .. "; in { nixos = builtins.attrNames f.nixosConfigurations;"
                .. " home = builtins.attrNames f.homeConfigurations; }"
              local spawned = pcall(vim.system,
                {"nix", "eval", "--impure", "--json", "--expr", expr},
                {text = true}, vim.schedule_wrap(report))
              if not spawned then
                warn("nix is not on PATH")
              end
            end
          '';
        }
      ];
    };
  };
}
