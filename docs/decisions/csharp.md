# decisions/csharp

## csharpier formats, roslyn is the fallback

**Why:** `format.type = ["csharpier"]` in `modules/languages/csharp.nix`
routes cs buffers to csharpier, and the invocation goes through a per-instance
`csharpier server` — an HTTP daemon spawned via `jobstart` on the first cs
buffer (`modules/csharpier-daemon.lua`, delivered by
`luaConfigRC.csharpier-daemon`), its port parsed from the `Started on` banner,
each format a curl POST of `{fileName, fileContents}` to `/format`, with
`fileName` resolving `.csharpierrc`/`.editorconfig` per file. This replaced
per-invocation `csharpier format` on 2026-09-01: every format paid the dotnet
runtime boot (~0.27 s warm, measured 2026-08-18); the daemon pays it once per
session. It is `jobstart`, not kotlin-lsp.md's flock/setsid machinery, because
SIGHUP-on-exit is the whole lifecycle a formatter needs — the daemon dies with
its editor, and a replacement costs about a second, not minutes.

The binary stays a bare `$PATH` name in **every** build — the rustfmt shape,
with the `dev` half of `modules/formatter.nix` deliberately absent (decided
2026-08-18, replacing the formatting-is-the-LSP's-job entry: a pinned fallback
was measured at 923.9 MiB — csharpier bundles its own dotnet runtime, sharing
nothing with the SDK the C# stack already ships — and refused) — but the
resolution now happens in the daemon's `jobstart`, not conform's `command`.
`command = lib.mkForce null` still beats the preset's normal-priority
`getExe pkgs.csharpier` and is what keeps that store path out of `min`; nvf
strips the null, and it must render absent — conform refuses a formatter
defining both `command` and a `format` function (observed 2026-09-01).
`"inherit" = false` (quoted; Nix keyword) keeps conform from merging its
builtin csharpier config — and its `dotnet csharpier` version probe — back
under the `format` function. The degradation is what makes the bare name
affordable: the `condition` requires csharpier *and* curl on `$PATH`, conform
skips the formatter when either is missing, and the global
`default_format_opts.lsp_format = "fallback"` then hands the buffer to
roslyn-ls, .editorconfig-driven — so a desktop launch with no devshell still
formats on save, just not through csharpier.

**Breaks:** three ways. Without csharpier (or curl) on `$PATH`, cs buffers
silently format through roslyn instead — a style flip with no error anywhere;
`:ConformInfo` is the diagnostic. A csharpier below 1.0 has no `server`
subcommand: one WARN notify on the first cs buffer, then that same silent
roslyn fallback for the rest of the session. And the entry's three keys are a
unit: a real name in `command` beside `format` trips conform's "Cannot define
both" refusal and cs stops formatting (visible in `:ConformInfo`); dropping
`"inherit" = false` merges the builtin config back in; and the preset's
`args = ["format"]` still concatenates if restated — inert today, but
`csharpier format format` ("no file or directory found at format" in
`conform.log`, observed 2026-08-18) the moment the `format` key is ever
removed.

**Also:** csharpier does not organize imports, so
`dotnet_organize_imports_on_format` (next entry) fires on an explicit LSP
format, and on save only when the roslyn fallback is the one formatting.
`min` has no LSP: there, no csharpier on `$PATH` means cs goes unformatted.
cs still formats *after* save rather than on it
(`docs/decisions/formatters.md#format-on-save-gates-on-a-global`); the daemon
just makes the reformat land near-instantly. The idle server costs about a
dotnet runtime of RSS per Neovim instance — the startup cost moved into
memory, accepted.

## Organize imports goes through vim.lsp.config

**Why:** `dotnet_organize_imports_on_format` is delivered by a
`vim.lsp.config("roslyn", …)` merge-call in `luaConfigRC`, not through
`require('roslyn').setup()` and not through `vim.lsp.servers`. The pinned
roslyn.nvim reads no `settings` key from its setup table — passing one is a
silent no-op — and the LSP client it enables is named `roslyn`, configured from
the plugin's own `lsp/roslyn.lua`; nvf's `vim.lsp.servers.roslyn-ls` table is
emitted but never started. An nvf `vim.lsp.servers.roslyn` entry would be
emitted as an *assignment*, which can clobber the plugin's own merge-call (the
one implementing `filewatching = "roslyn"`) depending on init.lua order; the
merge-call form composes regardless of order.

**Breaks:** silently, if roslyn.nvim renames its client or starts reading
`settings` from `setup()`. The check is
`:lua =vim.lsp.get_clients({name="roslyn"})[1].config.settings` showing the
`csharp|formatting` table.

## Razor is disabled until the pin catches up

**Why:** `extensions.razor.enabled = false`. The nixpkgs pin builds roslyn-ls
5.9.0-1.26314.1, which accepts `--extension` but not the
`--razorSourceGenerator=` / `--razorDesignTimePath=` flags nvf's Razor config
appends — the server rejects them and exits 1 on every start, and roslyn.nvim
restarts it in a loop, so Razor-enabled meant no C# LSP at all (observed
2026-08-10, `~/.local/state/nvf/lsp.log`). With the extension off, roslyn.nvim
launches plain `{exe, --stdio}` and the server runs. `.razor` files still match
the `roslyn` client's filetypes, just without Razor tooling. The unfree
`vscode-extension-ms-dotnettools-csharp` predicate stays — re-enabling once the
pin's roslyn-ls understands the flags means flipping `razor.enabled` **and**
removing the `cmd` override below.

The `cmd` in the `vim.lsp.config("roslyn", …)` merge-call is static —
`{ "Microsoft.CodeAnalysis.LanguageServer", "--stdio" }`, resolved from the
wrapper's `$PATH` where nvf puts roslyn-ls. That is the plugin's own migration
path: its default cmd is a function (`get_default_cmd`) that both assembles the
extension flags and fires a `vim.deprecate` notice whenever a non-empty
`extensions` table exists — and nvf always passes one, even with razor
disabled. The notice fires at client start, during buffer load, *before*
`VimEnter` — so the fidget wrapper below cannot catch it. A static `cmd` means
`get_default_cmd` never runs: no deprecate notice, no flags, same command line.

**Breaks:** silently, in one specific way: re-enabling razor without removing
the `cmd` override leaves the razor flags unbuilt — razor "on" but inert.
Check `:lua =vim.lsp.get_clients({name="roslyn"})[1].config.cmd`.

## Roslyn notifications go through fidget

**Why:** roslyn.nvim narrates its lifecycle with `vim.notify` — "Initializing
Roslyn for: …", "Roslyn project initialization complete". Those are progress,
not alerts, so they belong in fidget's corner with the rest of the LSP chatter,
while snacks/noice keep everything else (`modules/lsp-progress.nix` sets
`override_vim_notify = false` for exactly that split). The mechanism is the
plugin's own interface: `setupOpts.silent = true` suppresses the notify calls,
and the plugin fires `User RoslynOnInit` (with `data.type`/`data.target`) and
`User RoslynInitialized` at the same moments — two autocmds re-emit those
through `require("fidget").notify`, after an `lz.n` trigger-load, same as
`modules/direnv.nix`.

**Do not intercept `vim.notify` for this.** It was tried twice and lost twice,
because three parties fight over the global: snacks installs a self-replacing
shim (its first passthrough reassigns `vim.notify = Snacks.notifier.notify`,
evicting any wrapper above it), and noice is lazy-loaded on `DeferredUIEnter`,
where its `source/notify.enable()` captures whatever `vim.notify` is and
replaces it — outside any notify call, so no self-healing wrapper can survive
it. The User-autocmd route does not participate in that fight at all.

**Breaks:** silently, if roslyn.nvim renames its User events or stops gating
those messages behind `silent`. `silent` also mutes the same messages for
anyone not listening to the events — the autocmds and the flag are one unit;
remove both together. The check: opening a cs file in a solution should show
"Initializing Roslyn for: …" in fidget's corner and nothing in snacks/noice,
even after other notifications have fired.

## netcoredbg

**Why:** the coreclr debug adapter is Samsung's netcoredbg — MIT in nixpkgs, no
`allowUnfreePredicate` entry. Microsoft's vsdbg is proprietary and licensed for
use with Visual Studio products only, so it is not an option here.
`--interpreter=vscode` is the DAP wire protocol nvim-dap speaks. The adapter
and the cs launch configuration live in the csharp file (the language owns its
debug config); the generic `nvim-dap` + UI enable is `modules/debugger.nix`.

`dotnet-sdk_10` rides along in `vim.extraPackages` as a *fallback*, not a pin
that wins: mnw appends `extraPackages` to `$PATH` (`vim.env.PATH = vim.env.PATH
.. ":…"`), so a devshell's dotnet shadows it and the packaged SDK only serves a
host without one — launching from a desktop with no shell still restores,
builds and debugs. This is `gui` buying out-of-the-box weight `min` refuses,
the same split as `docs/decisions/formatters.md#dev-re-adds-a-pinned-fallback-core-does-not`.
The version is the newest LTS the pin carries, not the oldest supported: an SDK
design-time builds every *lower* target, never a higher one, so a too-old
fallback fails exactly when it is reached. Observed 2026-08-10 with `sdk_8`
against a net10.0 project: the design-time build failed, every reference came
back unresolved, and roslyn flagged all `using` directives IDE0005-unnecessary
— garbage diagnostics, not a roslyn bug. A failed restore looks the same;
`dotnet restore` in the project, then `:lsp restart roslyn`, is the first move
when every using lights up.
roslyn-ls itself needs no `$PATH` dotnet — its nixpkgs wrapper falls back to a
bundled runtime, and the Razor extension DLLs are loaded inside roslyn-ls via
`--extension`, never `dotnet <dll>`'d.

**Breaks:** at debug time, not build time. netcoredbg launches whatever DLL the
prompt is given; a stale path fails in the adapter with no Nix-level signal.
And the SDK fallback means a *broken* devshell dotnet still wins over the
working packaged one — preferPathExe's known trade, inherited here.
