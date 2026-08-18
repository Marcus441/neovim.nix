# conventions/overrides

How `core` and `dev` disagree about the same option. Both aspects merge into one
nvf evaluation, so where both set a key the module system's priorities decide.

## core states the default, dev states the value

**Why:** priorities are `mkDefault` = 1000, a plain value = 100, `mkForce` = 50,
and **lower wins**. So `core` says `lib.mkDefault false` and `dev` says a plain
`true`. That is the only combination that expresses "off in `min`, on in `gui`".
Every `lsp.enable` and `enableExtraDiagnostics` in the `core` half of a
`modules/languages/*.nix` has this shape.

**Breaks:** loudly, which is the good case. Two definitions at the same priority
do not merge for a bool, so a plain `false` in `core` errors the first time
`dev` disagrees. `mkForce` in `core` is the quiet failure — it wins, `dev`'s
value is discarded, and nothing says so.

**Also:** a `mkDefault` that nothing ever overrides looks deliberate and is just
noise. If no `dev` file sets the key, write the plain value.

## cmd needs mkForce

**Why:** nvf sets `lsp.servers.<name>.cmd` itself at normal priority, so a plain
assignment is a conflict, not an override. Every `cmd` in `modules/languages/`
carries `lib.mkForce` for this reason and no other.

**Breaks:** loudly at eval. The fix is never to drop the assignment — it is what
routes the server through `preferPathExe` (`docs/decisions/prefer-path.md`).

**Also:** `mkIf` gates a value but still evaluates it. When the excluded branch
names a package that may not exist, exclude by attribute with
`lib.optionalAttrs`, not by value with `lib.mkIf`.

## a formatter command needs mkOverride 40

**Why:** the ladder above assumes `core` can state its value with `mkDefault`.
For `formatters.<name>.command` it cannot — nvf's conform presets set it at
normal priority, so `core` is already spending `mkForce` (50) just to get a bare
name. `dev` disagreeing therefore has to go *below* that, and `lib.mkOverride 40`
is the only rung left. It is the sole place in the repo that needs one.

**Breaks:** loudly. Two `mkForce`s on a `str` do not merge — the error names the
option and both files, so it is the good kind. The quiet failure is the reverse:
writing `dev`'s value as a plain assignment, which loses to `core`'s `mkForce`
and leaves `dev` with the bare command it was meant to replace.

**Also:** this only arises where `core` must fight nvf for a scalar. `lsp.enable`
does not, because nvf leaves it at its default; `lsp.servers.<name>.cmd` does
not, because `dev` is the only aspect that sets it at all.
