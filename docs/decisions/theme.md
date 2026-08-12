# Theme

kanagawa dragon, and the values this config does not take from it.

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
**Also** the terminal owns *how* the curl is drawn and this file owns *what
colour* it is; the two are independent. `~/.dotfiles/flake` carries the other
half at `docs/decisions/terminal.md#terminal-stroke-weight` — undercurl
thickness and glyph-alpha contrast, per terminal.
