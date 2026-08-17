# decisions/statuscolumn

## One icon slot, stock gutter width

**Why:** snacks' default statuscolumn is `[mark/sign 2][number][fold/git 2]` —
two icon slots, so the gutter runs 2 cells wider than stock neovim's
`[sign 2][number 4]`. `modules/snacks-statuscolumn.nix` collapses to a single
left slot carrying all four sign types by priority (`fold`, `sign`, `git`,
`mark`) and the wrapper strips the now-constant 2-space right pad, bringing the
total back to stock's 6 columns on files under 100 lines. The trade: one icon
per line — a line with both a diagnostic and a git change shows only the
diagnostic, and a closed fold's chevron beats both (closed folds are rare and
deliberate, so the chevron is the higher signal).

**The number cell** is `max('numberwidth' - 1, digits(last line) + 1)` plus a
trailing space — stock neovim's own formula, except the `+ 1` where stock has
the last line's digits exactly. That extra column is the jut: the cursor line's
absolute number left-aligns and needs one cell of slack to be visibly offset
from the right-aligned relative numbers, whatever its digit count (`22c1d15`).
So files of 100+ lines run exactly one column wider than stock. Shaving it
reintroduces the bug `22c1d15` fixed.

## Functions, not lists

**Why:** `left` and `right` are Lua *functions* returning the component lists,
not the lists themselves, because snacks merges user config over its defaults
with `vim.tbl_deep_extend` — and an empty table can-merge, so a literal
`right = []` silently deep-merges into the default `{ "fold", "git" }` and
changes nothing. A function is not mergeable and replaces the default cleanly;
snacks calls it per render (statuscolumn.lua, `M._get`).

**Breaks:** silently. "Simplify" these to plain lists and the build still
succeeds, but the right slot comes back for fold/git icons: the wrapper's
2-space strip then no longer matches on lines with an icon, so the gutter
widens by 2 whenever a closed fold or git change is on screen, and jumps as you
scroll. Verify by rendering (pty + `screenstring()`), not by building.
