# decisions/images

## imagemagick is pinned, the rest of the toolchain is not

**Why:** snacks image shells out to `magick` to convert anything that is not a
PNG; without it only PNG files render. `full` launches from any terminal, not
from inside a devshell that could supply one, and the pin costs 121.8 MiB
measured against `gui`'s 6.1 GiB (imagemagick's own 219 MiB closure mostly
overlaps what is already there) — the cheapest format coverage available.

**Breaks:** silently. A missing `magick` does not error — non-PNG images just
stop appearing, and the only diagnostic anywhere is `:checkhealth snacks`.

**Also:** PDFs still do not render: `magick` delegates PDF rasterising to
ghostscript, and nixpkgs builds imagemagick without that delegate. Deliberate —
the fix would be a ghostscript pin nobody has asked for.

## math rendering is disabled

**Why:** snacks' LaTeX/typst rendering shells out to `tectonic` or `pdflatex`,
and mermaid to `mmdc`, none of which are pinned — `mmdc` alone drags `nodejs`.
An enabled feature whose toolchain is absent is worse than a disabled one.

**Breaks:** silently. snacks defaults `convert.notify = false`, so a math block
with no LaTeX toolchain produces nothing at all — no error, no placeholder.
Re-enabling `math` without pinning a toolchain restores exactly that silence.

## neovide declines image rendering

**Why:** Neovide does not implement the kitty graphics protocol, so the `gui`
variant simply does not take the `images` aspect. The explicit
`image.enabled = false` in the `neovide` aspect exists because snacks
auto-enables any module whose key merely appears in its setup opts
(`opts[k].enabled = opts[k].enabled == nil or opts[k].enabled`) — a future file
touching `setupOpts.image.<anything>` in `core` or `dev` would switch the
renderer on under Neovide without it.

**Breaks:** silently — a broken renderer in Neovide, with no eval error.

**Also:** `images` and `neovide` both set `image.enabled` at plain priority, on
purpose. No variant takes both aspects; one that tried would fail loudly as a
definition conflict, which is the correct answer to a build that wants images
under Neovide.
