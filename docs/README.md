# docs/

Why the config is the way it is. The `.nix` files say what it is.

```
conventions/   patterns that recur across many files
decisions/     why one file made its call, grouped by area
```

Both are empty until the refactor gives them something to hold. An entry written
before the decision exists is speculation, and a register that drifts is worse
than none.

Most entries should be three lines — **Why** the value is what it is, **Breaks**
what goes wrong if you change it, and **Also** where there is a related trap.
**Breaks** is the line worth reading.

## Finding the reason for a line

Files carry no comments except a pointer, at the values where changing them
breaks something non-obviously. Nothing carries one yet — the shape, for when
Stage 5 writes the first entry:

```nix
# load-bearing: docs/decisions/languages.md#preferpath
cmd = lib.mkForce [ (preferPathExe "clangd" …) ];
```

A pointer to an entry that does not exist is worse than no pointer, so the two
land in the same commit.

The ones whose **Breaks** line says *silently* are the sharp end — they fail with
no error anywhere, so the pointer is the only warning. This repo has several
already: the `allowUnfreePredicate` that roslyn needs, the `$PATH` formatter
resolution that keeps `min` small, and `preferPath` preferring a possibly-broken
devshell binary over the pinned one.

## Where else things live

- **`CLAUDE.md`** — the invariants. What must stay true.
- **`.claude/rules/*.md`** — hazards and mechanics, loaded automatically by file
  path.
- **`REFACTOR.md`** — the live plan, deleted when its last stage lands.
- **`docs/`** — the rationale.

## Keeping these honest

**A decision changes ⇒ its entry changes, in the same commit.** Don't restate the
code: an entry that survives *"a careful reader would already know this from the
file"* is the only kind worth adding. Finished plans go to git history
(`CLAUDE.md` §10).
