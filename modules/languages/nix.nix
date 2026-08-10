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

      # load-bearing: docs/decisions/nix-lsp-split.md#reporting-the-precondition
      luaConfigRC.nixd-flake-check = ''
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

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "nix",
          once = true,
          callback = function()
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
          end,
        })
      '';
    };
  };
}
