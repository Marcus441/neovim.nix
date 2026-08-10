# decisions/csharp

## Formatting is the LSP's job

**Why:** `format.enable = false` in `modules/languages/csharp.nix`, and no
csharpier entry in `modules/formatter.nix`. csharpier was the one formatter
whose `gui` fallback was refused on closure size, so it was the one language
where `gui` formatting depended on a `$PATH` binary no desktop launcher
provides — while the roslyn-ls that `gui` already runs formats for free,
.editorconfig-driven. So `gui` sets
`formatter.conform-nvim.setupOpts.formatters_by_ft.cs = {lsp_format = "prefer";}`
and conform hands cs buffers to the attached LSP.

Disabling nvf's `format` section, rather than setting `format.type = []`, is
what makes that `cs` key safe to define: `formatters_by_ft` is `types.attrs`,
whose merge is an `//`-fold — two definitions of `cs` resolve by definition
order, silently, and a *nested* `mkForce` leaks its `_type` marker into the
generated Lua. With `format.enable = false`, nvf never defines `cs` and the
`gui` half is the sole owner.

**Breaks:** silently, and differently per build. `min` has no LSP, so C# is
entirely unformatted there — before this, a devshell csharpier on `$PATH` would
format it. That trade is accepted: `min` does C# as treesitter-plus-indent
only. Re-adding an external cs formatter means re-enabling `format` and putting
a name in `format.type`, not editing conform.

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

`dotnet-sdk_8` rides along in `vim.extraPackages` as a *fallback*, not a pin
that wins: mnw appends `extraPackages` to `$PATH` (`vim.env.PATH = vim.env.PATH
.. ":…"`), so a devshell's dotnet shadows it and the packaged SDK only serves a
host without one — launching from a desktop with no shell still restores,
builds and debugs. This is `gui` buying out-of-the-box weight `min` refuses,
the same split as `docs/decisions/formatters.md#gui-re-adds-a-pinned-fallback-core-does-not`.
roslyn-ls itself needs no `$PATH` dotnet — its nixpkgs wrapper falls back to a
bundled runtime, and the Razor extension DLLs are loaded inside roslyn-ls via
`--extension`, never `dotnet <dll>`'d.

**Breaks:** at debug time, not build time. netcoredbg launches whatever DLL the
prompt is given; a stale path fails in the adapter with no Nix-level signal.
And the SDK fallback means a *broken* devshell dotnet still wins over the
working packaged one — preferPathExe's known trade, inherited here.
