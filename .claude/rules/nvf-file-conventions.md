---
paths: "modules/**/*.nix,core/**/*.nix,gui/**/*.nix,min/**/*.nix"
---

# Writing a file under `modules/`

> The `core/`, `gui/` and `min/` globs above are the pre-refactor tree. Drop them
> from this file's frontmatter when Stage 1 lands and those directories are gone.

## The invariants, in full

1. **Every `.nix` file under `modules/` is a flake-parts module.** Not an nvf
   module, not a package expression, not a helper library. One interpretation,
   always. An nvf module appears only as the *value* of
   `flake.modules.nvf.<aspect>`.
2. **`flake.nix` is a manifest.** Inputs plus `mkFlake` plus `import-tree`. No
   configuration logic. Edited only to add an input.
3. **One file = one concern, across every aspect it touches.** A single file may
   declare both `core` and `gui` — that is the merge working as intended. The
   violation is one concern spread across several files.
4. **File paths name the feature but carry no system-meaning.** A path never
   encodes a variant or an aspect — the module system does not read it. Files
   move freely; directories are navigation, not structure.
5. **No manual import lists** except the variant wiring. `import-tree` discovers
   everything else.
6. **Aspects are variant-agnostic.** A file must not ask which build loaded it.
7. **`default`, `min` and `gui` are public API.** `~/.dotfiles/flake` reads
   `packages.${system}.min` and `.gui`.

## The merge runs in both directions

flake-parts is the *top-level configuration*. Every file participates in that one
evaluation. nvf modules are not imported from paths — they are stored as **option
values** under `flake.modules.nvf.<aspect>`, typed `deferredModule`, and those
attribute sets **merge**.

- **Many files → one aspect.** Growing a feature means *adding a file*, never
  editing a list.
- **One file → many aspects.** A single concern can contribute to `core` and
  `gui` at once. This is the direction that gets forgotten.

Two independent axes: the unit of **concern** is the *file*; the unit of
**applicability** is the *aspect*. Neither contains the other.

**There is one class here, not three.** The sibling flake's files are kept honest
by spanning `nixos` and `homeManager`; nothing plays that role here. The only
pressure keeping a concern in one file is the aspect axis, so it is the one to
watch.

> **Declare options; do not lean on `flake.modules` alone.** The dendritic
> README's "Not declaring options" anti-pattern. `modules/aspects.nix` declares
> `flake.modules` and `aspectRequires` with `deferredModule` type.

## The shape of a file

```nix
{
  flake.modules.nvf.core = {
    vim.languages.rust = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {
    vim.languages.rust.lsp.enable = true;
  };
}
```

One file, one language, both builds. The `lib` in scope inside
`flake.modules.nvf.*` is nvf's, not flake-parts' — see `evaluation-hazards.md`.

## Read before writing a new file

Until Stage 1 lands there are **no exemplars in this tree** — every file is
single-aspect because the variant split is still done by directory. Check
CLAUDE.md §8 before treating any file as an example.

The closest thing to the target shape today is `gui/database.nix`: one concern
(dadbod) carrying its plugins, its Lua, *and* its keymap in one file. Its fault
is only that the file sits under `gui/`.

The sibling flake's `modules/filemanager/thunar.nix` is the canonical exemplar of
one concern declaring several memberships, if you want to see the shape working.

## Directories

**Test:** if every file inside declares the same declining aspect, the directory
is redundant and the files should be flat. If the files span declining aspects,
the directory is pure navigation and is fine. **`core` does not count toward
"several aspects"** — every variant takes `core`.

`languages/` is fine: every file in it declares both `core` and `gui`, so the
directory predicts nothing. A `gui/` directory holding only `gui` files is
exactly what Inv. 4 forbids.

## Assets and non-modules

`import-tree` imports **`.nix` files only**. A `.lua`, `.json` or `.md` asset
lives at any ordinary path and is read with `builtins.readFile` — it does not
need a `/_` prefix, and the sibling flake keeps `modules/discord/*.json` at a
plain path for exactly this reason.

`/_` is for **`.nix` files that are not modules**: expressions consumed by
`import`, derivations consumed by `callPackage`, dormant code. `import-tree`
skips any path matching `hasInfix "/_"`. **It is not a grouping mechanism.**

## A helper used by more than one file

`preferPath` (`gui/languages.nix:6`) is a `let` binding today, which is correct
while one file uses it and fatal the moment Stage 2 splits that file per
language. In order of preference:

1. **`let` binding** — when only that file needs it.
2. **A flake-parts option** — when other files need it. Capture the flake-parts
   `config` in an outer `let`; inside `flake.modules.*`, `config` is nvf's.
3. **A `/_` expression consumed by `import`** — for a pure function that has no
   business being an option.

**Forbidden:** a `lib/` directory (Inv. 1), and importing a module file by path
to call a function out of it.
