# Theme

kanagawa dragon, and the values this config does not take from it.

<a id="picker-blocks"></a>
## `kanagawa-setup.lua` — the picker, completion, input, cmdline and notifier are opaque blocks

**Why** the same file sets `NormalFloat`, `FloatBorder` and `FloatTitle` to
`bg = "none"`, so every float is a wire frame over the terminal. These five are
the deliberate exception: they are read as *panes*, and a pane is separated from
its neighbour by shade, not by a drawn line. Three shades, one step apart in
dragon, and each reused for the role it plays: `bg_p1 #282727` where you type
(picker prompt, `vim.ui.input`, cmdline), `bg_m1 #1D1C19` for a list of choices
(results, completion menu, notification), `bg_dim #12120f` for what a choice
*is* (preview, completion docs, signature help). Each window's border is painted
in its own colour, which is what turns `border = "solid"` from a frame into a
cell of padding. Titles need that border row to render at all, so `"none"` is
not the same thing.
**Breaks** *Silently.* It works only because each plugin's `winhighlight`
redirects `NormalFloat` away from the global group: snacks builds
`SnacksPicker{,Input,List,Preview,Box}` from `picker/util/highlight.lua`, blink
uses `BlinkCmp{Menu,Doc,SignatureHelp}`, and noice maps `NoiceCmdlinePopup` /
`NoicePopupmenu`. Drop a `bg` here and the group falls back through that
redirect to `bg = "none"` — the tiers collapse into one transparent pane, and
nothing errors. Drop the matching `border` entry and the padding turns back into
a visible frame in the wrong colour.
**Also** the *border style* is not set here. It lives with each plugin —
`modules/snacks-picker.nix`, `modules/snacks.nix`, `modules/snacks-notifier.nix`,
`modules/auto-complete.nix`, `modules/noice.nix` — because nvf sets none of them
and `vim.options.winborder` (`"single"`, still the global default) is what they
would otherwise inherit. Colour and style have to change together or the block
reads as a mis-coloured frame.
**Also** fidget goes the *other* way, and the reason is that it has no
neighbour. A block separates one pane from the next; LSP progress is a single
transient corner toast with nothing beside it, so a block there is decoration.
It also paints nothing — fidget's `winblend = 100` means the interior never
renders, which is deliberate: a long progress message must not blank out the
code under it. `modules/lsp-progress.nix` therefore sets
`notification.window.border = "none"`, restoring fidget's *own* default.
`vim.ui.borders.globalStyle` had overridden it to `"single"`, which framed a
window that draws no background — buffer text visibly bleeding through a hard
border. **Do not "fix" that by lowering `winblend`.**
**Also** `modules/borders.nix` is now load-bearing for a reason it was not
before: `vim.ui.borders.enable` is what switches noice's `lsp_doc_border` on,
and the entry above depends on that frame existing in order to paint it out.
Its only other live consumers are `:LspInfo`'s windows. Turning it off would
silently flatten the hover doc against the buffer.
**Also** the LSP hover doc is the exception that needs no style change, and the
reason is worth knowing before touching it. noice owns `textDocument/hover` here
— the float's `winhighlight` is `Normal:NoicePopup,FloatBorder:NoicePopupBorder`
— and its `lsp_doc_border` preset, which nvf switches on from
`vim.ui.borders.enable`, draws a *rounded* frame with **nui**, inside the window,
not as a Neovim border. There is nothing to set to `"solid"`. Painting
`NoicePopupBorder`'s `fg` to match its `bg` hides the glyphs and leaves the cell,
which is the original Telescope trick rather than the `solid` variant — same
result, different mechanism. `min` never hits this: it has no LSP and no noice.
**Also** all three plugins register these groups themselves with
`nvim_set_hl(…, { default = true })` and re-apply them on `ColorScheme`. That is
what makes this file the right place: `default = true` will not overwrite a
group that already exists, and kanagawa's `overrides` run *during* the
`:colorscheme` command, before the event fires. An override applied from an
autocmd instead would land in `vim.autocmds`, whose order is load-bearing.
**Also** snacks' `styles.notification` defaults to `winblend = 5`, which makes
the block translucent again; `modules/snacks-notifier.nix` sets it to 0. The
notifier's *border* keeps its per-level diagnostic `fg` because the `fancy`
style draws its rule with that group.
**Also** `modules/session.nix` sets `usePicker = false` for this. nvf adds
`dressing-nvim` to `startPlugins` whenever nvim-session-manager wants a picker
UI, and dressing *patches* `vim.ui.input` and `vim.ui.select` at load, taking
them off snacks. It carries its own `border = "rounded"` and nvf exposes no
option to configure it, so the only lever is not loading it. With it gone,
snacks owns both prompts in `gui` as it already did in `min`, and the session
picker falls through `vim.ui.select` to the snacks picker.

<a id="diag-error"></a>
## `kanagawa-setup.lua` — `diag.error` is waveRed, not dragon's own samuraiRed

**Why** sRGB weights luminance R 0.2126, G 0.7152, B 0.0722, so red carries a
fraction of the perceived brightness of a green at the same saturation, and a
thin antialiased stroke survives on luminance contrast alone. An undercurl is
the thinnest stroke an editor draws, so the error squiggle is where that fails
first. Dragon's `diag.error` is `samuraiRed #E82424`, a holdover from the wave
palette, which sits at **4.04** against the `#181616` background — below every
other diagnostic colour and below the foreground's 10.76. `waveRed #E46876`
is 5.61, and it is also `base12` in `~/.dotfiles/flake`, the terminal's ANSI
bright red — so an error reads as the same red in the editor and in the shell.
**Breaks** *Silently, and in more places than the squiggle.* One value feeds
`DiagnosticUnderlineError.sp`, `DiagnosticError`, `DiagnosticSignError`,
`DiagnosticFloatingError`, `SpellBad.sp`, `ErrorMsg` and `Error`, plus
`NeoTreeGitConflict`, `healthError` and the DAP and test groups. The
`makeDiagnosticColor` override reads `theme.diag.error` too, so the virtual-text
tint follows without being named. Nothing reports a colour that merely became
hard to see.
**Also** `@comment.error` reads this value as a **background**, with `ui.fg` over
it, so brightening the red makes *that* pairing worse — 2.66 at samuraiRed, 1.92
at waveRed. Its override here flips the foreground to `ui.bg`, dark on red,
which is 5.61 and is what kanagawa itself does for `MiniHipatternsFixme`. Check
whether a colour is ever read as a background before rebalancing it.
**Also** `base08 #c4746e` is the obvious candidate and was rejected. base16
convention makes base08 the error slot, but dragon is not a base16 scheme: it
spends `dragonRed` on five syntax roles — `operator`, `preproc`, `regex`,
`special2`, `special3` — before it reaches ANSI slot 1, and measured in the
editor `Operator`, `@operator` and `PreProc` all resolve to it. An error in that
colour is the colour of every `=` and `#include` on screen. `waveRed` carries
exactly one role in dragon, ANSI slot 9, and no syntax role at all, which is
what leaves it free. It is also the stronger fix, 5.61 against 5.21. Upstream's
own answer to the same collision is `samuraiRed`, a red that appears nowhere in
dragon's `term` table — so putting diagnostics *into* that table is this
config's departure, and the reason is contrast.
**Also** the terminal owns *how* the curl is drawn and this file owns *what
colour* it is; the two are independent. `~/.dotfiles/flake` carries the other
half at `docs/decisions/terminal.md#terminal-stroke-weight` — undercurl
thickness and glyph-alpha contrast, per terminal.
