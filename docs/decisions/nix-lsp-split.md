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

`formatting.command` is set to `alejandra` for consistency with
`modules/formatter.nix`, and is inert as written — `nixd`'s
`documentFormattingProvider` is cleared by the partition above, and conform-nvim
owns format-on-save. It is one line, and it is the line that would have to be
right the moment the partition moves.

**Breaks:** silently, in the way that config reading the outside world always
does. A missing `~/.dotfiles/flake`, an evaluation error in it, or a renamed
host attribute does not stop `nixd` from attaching or produce a message — with
`nixd`'s diagnostics suppressed there is nowhere for the complaint to surface.
Completions just come back empty, which is indistinguishable from having nothing
to complete. `:LspLog` after triggering a completion is the check; failing that,
evaluating the `expr` string by hand under `nix eval --impure` reproduces it in
one step.

**Also:** this is the second thing in the tree that reads the outside world and
fails to an empty result rather than a report — `modules/database.nix` is the
first, and `.claude/rules/lua-in-nix.md` asks that a third be argued for rather
than added. The shared cost is that the build succeeds on a machine where the
feature cannot possibly work.
