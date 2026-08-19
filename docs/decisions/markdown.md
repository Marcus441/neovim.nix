# decisions/markdown

## the preview needs node on PATH

**Why:** nvf's `markdownPreview` module adds the plugin to `startPlugins` and
sets the `mkdp_*` globals, and nothing else. nixpkgs builds
`markdown-preview-nvim` to run `app/index.js` under node and records that as
`runtimeDeps` on the derivation — but nvf wraps through **mnw**, whose
`extraBinPath` is `config.vim.extraPackages` and only that. `runtimeDeps`
appears nowhere in mnw. The `pkgs.nodejs` in `modules/markdown-preview.nix` is
the only thing putting node where the plugin can find it.

**Breaks:** silently. `:MarkdownPreviewToggle` opens no tab, prints no error and
leaves no message in `:messages`. The plugin is loaded and the command exists;
it just spawns nothing.

**Also:** `pkgs.nodejs` itself costs nothing — `dev` already drags it in through
the prettier pin (`formatters.md#dev-re-adds-a-pinned-fallback-core-does-not`),
so this line buys `$PATH` placement and no bytes. The plugin beside it is a
different matter; see `#the-closure-cost-lands-in-dev-not-min`. Both are why the
preview is `dev`-only: `min` has no node and would get exactly this silence.

## latex rendering is disabled

**Why:** render-markdown converts math by shelling out to `latex2text` from
pylatexenc, which nothing here pins. Same call, same reasoning as
`images.md#math-rendering-is-disabled` — an enabled feature whose toolchain is
absent is worse than a disabled one.

**Breaks:** silently. A `$$` block renders as its own raw source and nothing
says why; only `:checkhealth render-markdown` names the missing converter.
Re-enabling it without pinning pylatexenc restores exactly that.

**Also:** `sign.enabled = false` sits in the same `setupOpts` for an unrelated
reason — the gutter is hand-rolled to stock Neovim's width
(`statuscolumn.md#hand-rolled`) and `modules/diagnostics.nix` already sets
`signs = false`, so heading icons in the sign column would contradict both. That
one fails visibly and earns no pointer.

## the closure cost lands in dev, not min

**Why:** measured against `24d3f78` on 2026-08-19, `min` grows **1.5 MiB** —
render-markdown.nvim's Lua and the two treesitter grammars — and that is the
whole of what reaches every host. `full` and `gui` grow **265.7 MiB**, split in
a way that does not match the intuition: markdown-preview.nvim's bundled
`node_modules` is **157.6 MiB** of it, marksman with dotnet runtime 9 is
**95.5 MiB**, and markdownlint-cli2 is **11.8 MiB**. Marksman is cheaper than it
looks because roslyn's `dotnet-sdk_10` already paid for most of its closure;
only the runtime-9 derivation is new.

**Breaks:** visibly — the number moves and `verify.sh` reports it. The quiet
regression is the opposite direction: promoting any of these three to `core`
puts them in `min`, which is the exact failure
`formatters.md#path-resolution` exists to prevent.

**Also:** marksman is pinned rather than left bare, unlike rustfmt and
csharpier, because it has no fallback. Those two lose to a language server that
formats anyway; a `gui` launched from a desktop launcher has no devshell, and a
bare `marksman` there means no markdown LSP at all. 95.5 MiB against `gui`'s
6.36 GiB is the price of that, and it is the same trade
`images.md#imagemagick-is-pinned-the-rest-of-the-toolchain-is-not` made at
121.8 MiB.
