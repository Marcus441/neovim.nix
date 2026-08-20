# docs/

Why the config is the way it is. The `.nix` files say what it is.

```
conventions/   patterns that recur across many files
decisions/     why one file made its call, grouped by area
```

An entry written before the decision exists is speculation, and a register that
drifts is worse than none.

Most entries should be three lines — **Why** the value is what it is, **Breaks**
what goes wrong if you change it, and **Also** where there is a related trap.
**Breaks** is the line worth reading.

## Finding the reason for a line

Files carry no comments except a pointer, at the values where changing them
breaks something non-obviously:

```nix
# load-bearing: docs/decisions/prefer-path.md#silent-fallback
config.preferPathExe = pkgs: name: fallbackExe:
```

Twenty-seven files carry one today — `modules/nixpkgs.nix`, `modules/prefer-path.nix`,
`modules/clipboard.nix`, `modules/auto-complete.nix`, `modules/session.nix`,
`modules/lsp-progress.nix`, `modules/noice.nix`, `modules/snacks-picker.nix`,
`modules/oil.nix`, `modules/diagnostics.nix`, `modules/statuscolumn.nix`,
`modules/markdown-preview.nix`, `modules/languages/markdown.nix`,
`modules/languages/json.nix` and `modules/neovide.nix`,
`modules/formatter.nix` (five), `modules/languages/rust.nix` (two),
`modules/languages/yaml.nix` (two), `modules/languages/html.nix` (two),
`modules/languages/css.nix` (three), `modules/languages/openapi.nix` (three),
`modules/direnv.nix` (three),
`modules/images.nix` (three), `modules/splits.nix` (three),
`modules/languages/nix.nix` (five), `modules/languages/kotlin.nix` (six) and
`modules/languages/csharp.nix` (seven). The twenty-eighth is
`modules/kanagawa-setup.lua`, where the pointer is a `--` rather than a `#`
because the value it marks is Lua — subject to the two-line cap that governs
everything shipping into `init.lua`, which a one-line pointer meets.
The test is the **Breaks** line: a value
that fails *silently* earns a pointer, one that fails loudly does not. The
`mkOverride 40` in `modules/formatter.nix` is the one that looks like an
exception and isn't — the wrong override *errors*, but the plausible mistake
next to it, a plain assignment, loses to `core` without a word.

A pointer to an entry that does not exist is worse than no pointer, so the two
land in the same commit.

The ones whose **Breaks** line says *silently* are the sharp end — they fail with
no error anywhere, so the pointer is the only warning. This repo has several
already: the `allowUnfreePredicate` that roslyn needs, the `$PATH` formatter
resolution that keeps `min` small, `preferPath` preferring a possibly-broken
devshell binary over the pinned one, and the Nix LSP split, where a dropped
`handlers` entry doubles every diagnostic. The Nix split is also the one place
that answers the objection: its flake precondition is checked and *reported*,
so deleting the check is what restores the silence.

## Where else things live

- **`AGENTS.md`** — the invariants. What must stay true.
- **`.claude/rules/*.md`** — hazards and mechanics, loaded automatically by file
  path.
- **`docs/`** — the rationale.

## Keeping these honest

**A decision changes ⇒ its entry changes, in the same commit.** Don't restate the
code: an entry that survives *"a careful reader would already know this from the
file"* is the only kind worth adding. Finished plans go to git history
(`AGENTS.md` §10).
