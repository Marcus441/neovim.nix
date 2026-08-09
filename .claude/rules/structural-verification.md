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

## Proving "order-only" when the store path moves

Store-path equality is the strongest proof, but a refactor that reorders `listOf`
options cannot produce it. The gate is then **"the diff is order-only"**, and
that is a claim you prove, not one you assert from a small-looking diff.

The method Stage 0 used, and the one every later stage should reuse:

1. Extract `init.lua` from both builds — `$out/bin/nvf-print-config-path` names it.
2. For each order-sensitive region, split it into its **records** and re-emit
   them sorted, in *both* files. The regions are the `augroups` table, the
   `nvf_autocommands` table, the `vim.keymap.set` statements in
   `-- SECTION: mappings`, the treesitter queries, and any plugin `setupOpts`
   list that two modules both define (`blink-cmp`'s `keymap.<key>` and
   `sources.default` are the known ones).
3. Diff the canonicalised files. **Whatever survives is real content change.**
   Justify it line by line or fix it; a residual line is never "probably fine".
4. Assert the record count per region is unchanged. A permutation preserves it;
   a dropped or duplicated entry does not, and would otherwise hide inside a
   sorted comparison.

**Order-only is not the same as behaviour-preserving.** Where two modules define
the same key in a concatenated list, the first one wins at runtime, so a pure
reorder can change what a key does. Stage 0 flipped blink's `<C-d>` this way.
Check the contested keys, not just the record counts.

## `min` is the control

`min` takes only `core`. Any change confined to the `gui` aspect must leave `min`
identical — if it doesn't, something leaked into `core`.

## Flakes only see tracked files

`git add -A` before every `nix` command, or a freshly written module is invisible
and the error names a missing path rather than the real cause. A PreToolUse hook
does this automatically; `verify.sh` does it too.
