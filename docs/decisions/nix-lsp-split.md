# decisions/nix-lsp-split

## Capability partition

**Why:** `nil` and `nixd` both run on every Nix buffer, and each is better at a
different half of the job. `nixd` evaluates the real flake, so its completions
know the attributes that actually exist; its diagnostics and navigation cost an
evaluation and lag. `nil` is a pure static analyser — fast, evaluation-free
diagnostics, hover and rename, and completions that only ever guess. So `nixd`
keeps `completionProvider` and nothing else, `nil` keeps everything except
`completionProvider`, and the split is enforced in `on_attach` by mutating
`client.server_capabilities` rather than by asking either server to stand down.
Server capabilities are the right lever because `client:supports_method` reads
them: blink-cmp, `gd`, `<leader>ca` and every other consumer route through it,
so one edit covers all of them at once.

`nixd`'s allowlist keeps `textDocumentSync` and `positionEncoding` alongside
`completionProvider`. Neither is a method — they are the transport that carries
buffer changes to the server, and dropping them leaves `nixd` completing against
the file as it was on open.

**Breaks:** silently, and asymmetrically. Push diagnostics are the trap:
`textDocument/publishDiagnostics` is a server-initiated notification, so it is
not gated by `server_capabilities` at all and survives the allowlist untouched.
That is what the no-op `handlers` entry on `nixd` is for, and removing it
restores doubled diagnostics on every Nix buffer with no error anywhere — it
reads as a linter that repeats itself. `vim.diagnostic.get(0, {namespace = id})`
per namespace is the check; `nvim.lsp.nixd.*` should be `0`.

The mirror failure is quieter still. Clearing `completionProvider` on `nil`
removes it from blink's source list, so if `nixd` stops attaching — a bad
`settings` expression is enough, see below — Nix completion does not degrade to
`nil`'s, it disappears. Two clients on the buffer and zero completions is the
symptom; `:lua =vim.lsp.get_clients({bufnr=0})` distinguishes it from a server
that failed to start.

**Also:** `vim.lsp.servers.<name>` is a freeform submodule
(`nvf/lib/languages.nix`), which is why `handlers` and `settings` can be set at
all — only `enable`, `capabilities`, `on_attach`, `filetypes`, `cmd` and
`root_markers` are declared, and everything else rides `freeformType` straight
into `vim.lsp.config[<name>]`. See `docs/conventions/overrides.md` for the
`mkForce` both `cmd` values need against nvf's presets.

## nixd evaluates the system flake

**Why:** `nixd`'s completions are only worth having if it can evaluate
something, so `settings.nixd` points it at `~/.dotfiles/flake` — `nixpkgs` at
that flake's own pinned `nixpkgs`, and `options.nixos` / `options.home_manager`
at the configurations for *this machine*. The whole table is built in Lua at
startup rather than written out in Nix because the host is not knowable at build
time: this flake's `min` output ships to `gpc`, `swift5` and `UM790pro` alike,
and a store path holding `nixosConfigurations.UM790pro` would give the other two
machines completions for someone else's config. `vim.fn.hostname()` matches the
attribute name because the system flake sets `networking.hostName` from the same
key it names the host by; `vim.env.USER` matches the `marcus@<host>` half of
`homeConfigurations` for the same reason.

There is no `formatting.command`. `nixd`'s `documentFormattingProvider` is
cleared by the partition above and conform-nvim owns format-on-save, so the
setting would never be read; if the partition ever moves, it comes back in the
same edit that moves it.

**Breaks:** loudly now, but only at the edges the check below covers. What
remains silent is the case where the flake evaluates and names this host, yet
`nixd` still cannot use it — a wrong or missing `inputs.nixpkgs` is the live
example. `nixd` does not report that either; it falls back to a default
`nixpkgs` off `NIX_PATH` and keeps completing, so `pkgs.` returns 25 plausible
attributes from the wrong tree and nothing anywhere says so. Comparing a
`pkgs.` completion against `nix eval --impure --expr 'builtins.attrNames (import
(builtins.getFlake "~/.dotfiles/flake").inputs.nixpkgs { })'` is the only check
that distinguishes them.

**Also:** the option half fails differently from the `nixpkgs` half, which is
worth knowing before debugging one as the other. A bad `options` expr does not
return empty — the request never returns at all, measured past 200 s, so
completion simply never appears. Empty means *evaluated and found nothing*;
absent means *hung*.

## Reporting the precondition

**Why:** the failure above is invisible from inside Neovim — `nixd` emits no
`window/showMessage` and no `window/logMessage` when its flake is unreachable,
measured at zero messages — and it cannot be detected by watching completions
either, because the `nixpkgs` half lies plausibly and the options half hangs. So
the check has to run against the *inputs*, before `nixd` is handed them:
`luaConfigRC.nixd-flake-check` stats the flake on the first Nix buffer, then
asks Nix for the two output name lists and confirms this host is in both.

It is affordable because `builtins.attrNames` does not force the configurations
themselves — 0.142 s warm for all three hosts, against the minutes a real
evaluation costs. It runs once per session, `vim.system` is asynchronous, and
nothing about it can delay a completion.

**Breaks:** by returning to silence, which is the state this repo had before it
and reads exactly the same. Deleting the autocmd does not fail any build or any
test; it removes the only warning on a path that otherwise degrades invisibly.
The `pcall` around `vim.system` is load-bearing for the same reason — `gui`
launches from a desktop launcher with no devshell, and a missing `nix` on
`$PATH` would otherwise throw inside the callback where nobody reads it.

All five paths are checked: correct flake stays silent; missing flake,
non-evaluating flake, host absent from either output, and `nix` absent from
`$PATH` each name what is wrong.

**Also:** this is the third thing in the tree that reads the outside world, after
`modules/database.nix` and `modules/direnv.nix` — but it is the first that
reports rather than failing to an empty result, which is what
`.claude/rules/lua-in-nix.md` asks for when a fourth is proposed. The residual
cost is unchanged: the build still succeeds on a machine where the feature
cannot work. It now says so.
