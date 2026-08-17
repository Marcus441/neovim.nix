# decisions/statuscolumn

## Hand-rolled

**Why:** the statuscolumn is a hand-written format function, not
snacks.statuscolumn, even though snacks is already in the closure. The wanted
behaviour is stock neovim's gutter — `[sign 2][number 4]`, same width, same
sign-priority rules — plus exactly two extras stock cannot do: the cursor
line's number left-aligns and juts out of the right-aligned relative numbers,
and a closed fold shows its chevron without a dedicated `foldcolumn`. Getting
that out of snacks meant fighting it: collapsing its two icon slots into one,
regex surgery on its rendered string, and passing Lua *functions* where lists
deep-merge against its defaults. Hand-rolled, the same result is ~25 lines
against stable core APIs: `%s` renders the native sign column (gitsigns,
diagnostics, priorities — true stock behaviour for free), `foldclosed()` is
all the fold state needed when only closed folds get an icon, and the chevron
sits in the number's trailing cell at zero extra width. No coupling to plugin
internals — a snacks bump cannot move the gutter.

**Dropped, deliberately:** snacks' click-to-fold handler, mark signs, open-fold
icons, and its fold/git highlight coupling. If one of those becomes wanted,
that is the point to reconsider the plugin, not to grow this function.

## Width

**The number cell** is `max('numberwidth' - 1, digits(last line) + 1)` plus the
trailing cell — stock neovim's own formula except the `+ 1`, where stock has
the last line's digits exactly. That extra column is the jut: the cursor's
absolute number needs one cell of slack to be visibly offset whatever its
digit count (`22c1d15`). So files under 100 lines land on stock's 6 columns
exactly, and 100+ run exactly one wider. Shaving the `+ 1` reintroduces the
bug `22c1d15` fixed — the jut silently vanishing on lines whose number is as
wide as the widest relative number.

**Breaks:** visually and silently, never at build time. Verify by rendering
(pty + `screenstring()`) at three points: a short file (stock width, jut), a
150+ line file with the cursor on a 3-digit line (jut survives), and a closed
fold (chevron in the trailing cell, no width change).
