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
