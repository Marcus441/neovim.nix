---
paths: "scripts/*"
---

# Structural verification — proving a refactor moved nothing

**The ordering model is a working model, not a mechanism.** Measure; do not
predict. The proof of equivalence is that two builds produce the **same store
path** — not that a diff looked small.

There are two distinct outputs to check. `default` is an alias of `min`, so
checking it is free but not informative.

```bash
git worktree add ../neovim-prev <previous-commit>

for a in min gui; do
  echo "=== $a ==="
  old=$(nix build --no-link --print-out-paths "../neovim-prev#$a")
  new=$(nix build --no-link --print-out-paths ".#$a")
  [ "$old" = "$new" ] && echo PASS || {
    echo "FAIL: $old -> $new"
    diff -rq "$old" "$new"
  }
done

git worktree remove ../neovim-prev
```

`scripts/verify.sh <ref>` automates this against any git ref (`verify.sh` with no
argument compares against `HEAD~1`; `verify.sh build` builds the current tree
only).

## Reading a FAIL

A differing store path is not automatically a defect. Work out which it is:

- **Innocent:** the generated `init.lua` differs only in the *order* of
  autocmds, augroups, keymaps or treesitter queries. Those are `listOf` options
  that concatenate in module order, so any file move or merge reorders them
  (`evaluation-hazards.md`). Stage 1 will produce this legitimately.
- **Not innocent:** a plugin appears or disappears, a package version changes, a
  Lua body differs in content rather than position, or the closure size moves. A
  closure jump of ~2 GB means a formatter stopped resolving from `$PATH`.

`diff -rq` on the two outputs answers this directly; `nvd diff` explains package
changes if it is on `PATH`.

## What a passing Stage 0 looks like

Stage 0 moves every file and changes no content, so **both outputs must be
byte-identical**. If they are not, the skeleton changed something — most likely
the module order handed to nvf, or the `pkgs` instantiation (`variant-wiring.md`).
That is the one stage where a FAIL is always a bug, and it is why Stage 0 exists
as its own commit.

## `min` is the control

`min` takes only `core`. Any change confined to the `gui` aspect must leave `min`
identical — if it doesn't, something leaked into `core`.

## Flakes only see tracked files

`git add -A` before every `nix` command, or a freshly written module is invisible
and the error names a missing path rather than the real cause. A PreToolUse hook
does this automatically; `verify.sh` does it too.
