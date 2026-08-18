# Theme

kanagawa dragon, and the values this config does not take from it.

<a id="picker-blocks"></a>
## `kanagawa-setup.lua` — the picker, completion, input, cmdline, notifier and confirm dialogs are opaque blocks

**Why** the same file sets `NormalFloat`, `FloatBorder` and `FloatTitle` to
`bg = "none"`, so every float is a wire frame over the terminal. These seven are
the deliberate exception: they are read as *panes*, and a pane is separated from
its neighbour by shade, not by a drawn line. Three shades, one step apart in
dragon, and each reused for the role it plays: `bg_p1 #282727` where you type
(picker prompt, `vim.ui.input`, cmdline, the confirm dialogs — noice's and
oil's), `bg_m1 #1D1C19` for a
list of choices (results, completion menu, notification), `bg_dim #12120f` for
what a choice *is* (preview, completion docs, signature help). Each window's
border is painted in its own colour, which is what turns `border = "solid"` from
a frame into a cell of padding. Titles need that border row to render at all, so
`"none"` is not the same thing.
**Breaks** *Silently.* It works only because each plugin's `winhighlight`
redirects `NormalFloat` away from the global group: snacks builds
`SnacksPicker{,Input,List,Preview,Box}` from `picker/util/highlight.lua`, blink
uses `BlinkCmp{Menu,Doc,SignatureHelp}`, and noice maps `NoiceCmdlinePopup` /
`NoicePopupmenu` / `NoiceConfirm`. Oil is the odd one out: it registers no
float groups at all, so `modules/oil.nix` sets the `winhighlight` itself —
`OilConfirm` / `OilConfirmBorder` exist nowhere but this file's overrides. Drop
a `bg` here and the group falls back
through that redirect to `bg = "none"` — the tiers collapse into one transparent
pane, and nothing errors. Drop the matching `border` entry and the padding turns
back into a visible frame in the wrong colour.
**Also** the *border style* is not set here. It lives with each plugin —
`modules/snacks-picker.nix`, `modules/snacks.nix`, `modules/snacks-notifier.nix`,
`modules/auto-complete.nix`, `modules/noice.nix`, `modules/oil.nix`,
`modules/diagnostics.nix` — because nvf sets none of them
and `vim.options.winborder` (`"single"`, still the global default) is what they
would otherwise inherit. Colour and style have to change together or the block
reads as a mis-coloured frame.
**Also** the confirm dialog is `solid` where noice's two cmdline views are
`"none"`, and the inconsistency is forced. Both dialogs that reach it —
nvim-session-manager's *Save changes?* (`session_manager/utils.lua`) and
Neovim's W11 *has changed since editing started* — are `do_dialog` prompts,
routed by `kind = "confirm"` to a view noice gives a static
`border.text.top = " Confirm "`. nui treats `"none"` as *borderless*, not as a
blank frame, and raises `text not supported for style:none` the moment a border
carries text; its `solid` is a char map of eight spaces, so the text survives
and lands on the padding row. The cmdline views escape this only because cmdline
messages have no title, so noice never sets `border.text` for them. That same
one group paints the padding *and* the title, which is why `NoiceConfirmBorder`
takes the block's `title` entry rather than its `border` one — `fg = bg` there
would hide the label it is meant to render.
**Also** oil's mutation-confirm window is the other confirm dialog, and it
inverts the mechanism above: `nvim_open_win` there passes no `title`, its
`border` comes straight from `confirmation.border`, and oil applies
`confirmation.win_options` verbatim to the window (`mutator/confirmation.lua`).
So the whole block lives in `modules/oil.nix`'s `setupOpts` — `border = "solid"`
plus the `winhighlight` redirect — and, title-free, its `OilConfirmBorder` takes
the block's plain `border` entry (`fg = bg`), not the noice title trick. Left
alone it would not even be a wire frame in the wrong colour: with no
`winhighlight`, the window falls to the global transparent `NormalFloat`, and
`solid` padding painted `bg = "none"` is invisible.
**Also** the native diagnostic float (`vim.diagnostic.open_float`) is a block
on the `preview` tier — it plays the hover-doc role, showing what a diagnostic
*is*. It inverts oil's split one step further: the float registers no highlight
groups and, unlike oil, exposes no `winhighlight` option either — the opts
`open_float` forwards to `open_floating_preview` have no such key — so the
redirect cannot be declared as config at all. Instead the `<leader>e` keymap in
`modules/diagnostics.nix` wraps the call and sets `winhighlight` on the winid
`open_float` returns, targeting `DiagnosticFloat` / `DiagnosticFloatBorder`,
which exist nowhere but this file's overrides. Style lives with the plugin as
ever: `float.border = "solid"` in `modules/diagnostics.nix`'s
`vim.diagnostics.config`. The builtin `<C-w>d` bypasses the wrapper and falls
to the transparent global `NormalFloat` — solid padding painted `bg = "none"`,
invisible, the same silent failure shape as oil's would-be.
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
