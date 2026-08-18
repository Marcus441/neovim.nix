# decisions/prefer-path

## Silent fallback

**Why:** `preferPathExe` wraps a language server in a shell script that execs
the `$PATH` binary when one exists and the pinned one otherwise. It exists so a
project's own toolchain wins inside a devshell — the pinned server is the floor,
not the ceiling.

**Breaks:** silently, by design. A broken or stale `$PATH` binary beats a
working pinned one with no diagnostic anywhere: the wrapper cannot tell a
deliberate devshell override from an accident, so it does not try. Symptom is a
language server that misbehaves only inside one project. `command -v <name>` in
that directory is the check.

**Also:** the option is declared `functionTo raw` and takes `pkgs` explicitly
because the top-level flake-parts `config` is not per-system; a language file
reaches it by capturing `config` in an outer `let`. Weak typing is the accepted
cost of that shape, chosen over a `/_` expression so no language file carries a
relative import path. See `docs/conventions/overrides.md` for the `mkForce` that
every `lsp.servers.*.cmd` needs alongside it, and for the `mkOverride 40` that a
formatter's `command` needs instead.

## rustaceanvim owns activation

**Why:** nvf's rust module does not route through `vim.lsp.servers` — it writes
`vim.g.rustaceanvim.server.cmd` and rustaceanvim starts the client itself. The
`vim.lsp.servers.rust-analyzer` entry in `modules/languages/rust.nix` exists only
to *feed* it: rustaceanvim reads `vim.lsp.config["rust-analyzer"]` and merges it
over its own `server` table with `force`, so the `preferPathExe` wrapper wins.
`enable = false` keeps the entry out of nvf's `vim.lsp.enable(…)` list while
still emitting the config table, because nvf emits every server it knows and
filters only the enable list.

**Breaks:** silently, by duplication. With `enable` left at its default `true`,
Neovim's own `vim.lsp.enable` starts a *second* rust-analyzer alongside
rustaceanvim's — two processes indexing one crate, doubled diagnostics. It looks
like a slow editor, not a misconfiguration. `:lua =#vim.lsp.get_clients()` on a
Rust buffer is the check; one is correct.

**Also:** the entry carries `filetypes = ["rust"]`, and not as a trigger — with
`enable = false` nothing fires regardless. It is a blast radius limit: a config
*without* `filetypes` matches **every** filetype, in both places that read it —
`:lsp enable` with no arguments collects it into any buffer's enable list
(`ex_cmd.lua` treats nil as match-all), and once enabled it attaches to every
buffer. That was observed 2026-08-10: a bare `:lsp enable`, run to nudge a slow
kotlin-lsp, put rust-analyzer on kotlin and C# buffers. Scoped to `rust`, the
worst case of an accidental enable is the duplicated-client failure above, on
rust buffers only. Since nvf `59b0dc3` ships a rust-analyzer preset, switched
on through `languages.rust.lsp`, both `mkForce`s are load-bearing: the preset
asserts `enable = true` and a `cmd` of its own at plain priority, so `enable`
carries `lib.mkForce false` and the `cmd` override overrides something real.
