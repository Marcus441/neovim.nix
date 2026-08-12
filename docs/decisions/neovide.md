# Neovide

The GUI's own renderer settings, which reach nothing the terminal builds do.

<a id="stroke-weight"></a>
## `neovide.nix` — the undercurl and the glyph get separate levers

**Why** Neovide draws with Skia, so none of the terminal-side rendering settings
in `~/.dotfiles/flake` apply to it — it is not running inside a terminal. Its
own two levers split the same way kitty's do, and for the same structural
reason. `neovide_text_contrast` reaches `SkSurfaceProps::new_with_text_properties`
and so acts on the **glyph atlas** only; the undercurl is drawn separately in
`grid_renderer.rs`'s `draw_underline`, which builds its own `Paint` from
`style.special(...)` and never touches that atlas. So thickening the curl needs
`neovide_underline_stroke_scale`, and nothing else will do it. Defaults are 0.5
and 1.0; `neovide_hinting` is already at its strongest default, `full`.
**Breaks** *Silently, twice over.* A `neovide_*` global neovide does not
recognise is simply never read — there is no unknown-setting diagnostic, so a
typo leaves the default in place and looks like a setting that did not help.
And `draw_underline` computes
`(stroke_size * underline_stroke_scale).max(1.).round()`, so the result is
rounded to whole pixels: a scale close enough to 1.0 lands on the same integer
and changes nothing at all, at whichever font size it happens to round down on.
**Also** these are vim globals, not `config.toml` keys — neovide's `Config`
struct has no field for any of them, so the sibling flake's
`programs.neovide.settings` cannot set them however plausible it looks. The
colour half of the same problem is `theme.md#diag-error`, and the terminal half
is `docs/decisions/terminal.md#terminal-stroke-weight` in `~/.dotfiles/flake`.
