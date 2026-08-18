---
description: >-
  Use before committing a structural change — moving, renaming, or regrouping
  files; adding, splitting, or renaming aspects; changing a variant's aspect
  list; or editing the generator or aspects.nix.
  Runs the invariant self-check, anti-pattern scan, ordering check, and
  verification.
---

# Structural change checklist

**Structural** = moving/renaming/regrouping files, adding/splitting/renaming
aspects, changing a variant's aspect list, editing `modules/variants/generator.nix`
or `modules/aspects.nix`.

## 1. Invariant self-check

If the change would violate one, **stop and say so.** Do not silently bend a rule
— the invariants are the whole value of this structure, and a single exception
metastasises.

1. Every `.nix` file under `modules/` is a flake-parts module.
2. `flake.nix` is a manifest — no configuration logic.
3. One file = one concern, across every aspect it touches.
4. File paths name the feature and carry no system-meaning.
5. No manual import lists except the variant wiring.
6. Aspects are variant-agnostic.
7. `default`, `min` and `gui` are public API.

## 2. Anti-pattern scan

| Anti-pattern | Why |
| --- | --- |
| `core/`, `gui/`, `min/` directories | Paths encode the variant (Inv. 4) |
| `lib/` directory of helpers | Not a flake-parts module (Inv. 1) |
| `default.nix` that only lists siblings | `import-tree` already loaded them (Inv. 5) |
| `imports = [ ./foo.nix ]` inside `modules/` | Same (Inv. 5) — a hook rejects it |
| `_` to group related `.nix` modules | `/_` is for non-modules only |
| Aspect named `minimal` / `extras` / `ide` | Magnitude or archetype, not a decision |
| A third aspect no variant declines | Structure without a decision |
| `mkEnableOption` per aspect | Variants compose by taking aspects |
| A file asking which variant loaded it | Aspects are variant-agnostic (Inv. 6) |
| Editing two files to add one language | Wrongly decomposed (Inv. 3) — but one file declaring two aspects is not this |
| Plain `false` in `core` where `gui` overrides | Needs `lib.mkDefault` |

**Directory test:** if every file inside declares the same *declining* aspect,
the directory is redundant and the files should be flat. `core` does not count
toward "several aspects" — every variant takes it.

## 3. Ordering check

`vim.augroups`, `vim.autocmds`, `vim.keymaps` and `vim.treesitter.queries` are
`listOf` options: they concatenate in module order, which is aspect order then
import-tree's depth-first alphabetical walk. That order reaches the generated
`init.lua` and the store path.

- Splitting an aspect? Put the new names where the old one sat.
- Merging or renaming files **will** reorder these lists. Expect it; explain it.
- `extraPlugins` and `luaConfigRC` are order-stable under file moves — they are
  ordered by `after` and by DAG entry name.

**Measure; do not predict.**

## 4. Verify

```bash
./scripts/verify.sh build        # both outputs — the real check
nix flake check                  # cheap eval sweep
./scripts/verify.sh <ref>        # prove nothing changed but order
```

`verify.sh` proves equivalence by comparing **store paths**. Reading a FAIL:

- **Innocent** — the diff is the *order* of autocmds/augroups/keymaps/queries.
- **Not innocent** — a plugin appears or disappears, a version moves, a Lua body
  differs in content, or the closure size jumps (~2 GB means a formatter stopped
  resolving from `$PATH`).

`min` is the control: a change confined to `gui` must leave `min` identical.

**A pure file move must be byte-identical on both outputs.** It moves
files and changes no content, so a FAIL there is always a bug — most likely the
module order handed to nvf, or the `pkgs` instantiation losing its
`allowUnfreePredicate`.

Do not claim a build works without having built it.

## 5. Debugging

**Bisect eval errors** by temporarily renaming a file to `_name.nix` —
`import-tree` skips any path matching `/_`. Halve the tree until the build
recovers. Undo before committing.

**Inspect a merged aspect:** `nix repl` → `:lf .` →
`config.flake.modules.nvf.gui`.

**Read the generated config:** `nix build .#gui`, then look inside `result/` —
the assembled `init.lua` is the ground truth for every ordering question.

## 6. Commit

- Small, single-concern commits. Rationale in the commit message, not in
  comments.
- No unrequested changes: no plugin bumps, no deprecation fixes, no reformatting
  files the task doesn't touch.
- If a file gained or lost an aspect membership, run
  `scripts/recount-aspects.sh` and update the figure in
  `.claude/rules/nvf-file-conventions.md` if it has one.
- If a task touched a file listed under AGENTS.md §8 *Known divergences*, migrate
  it in the same change or state why not. Close the item when it is done.
- Finished plans go to git history. Cite a §-number or commit hash, never a plan
  filename.
- **Do not push.** The consuming flake pins a revision; publishing is the
  human's call.
