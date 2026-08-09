---
paths: "modules/**/*.nix,core/**/*.nix,gui/**/*.nix,min/**/*.nix"
---

# Evaluation hazards

## Overriding across aspects is the central mechanic

`core` and `gui` are merged into one nvf evaluation. Where both set the same
key, the module system's priorities decide, and only one combination works:

| `core` says | `gui` says | Result |
| --- | --- | --- |
| `lib.mkDefault false` | `true` | **gui wins.** The intended shape. |
| `false` | `true` | **Error** — two definitions at the same priority, no merge for a bool. |
| `lib.mkDefault false` | `lib.mkDefault true` | **Error** — same priority again. |
| `lib.mkForce false` | `true` | core wins. Almost always a mistake. |

Priorities: `mkDefault` = 1000, a plain value = 100, `mkForce` = 50. **Lower
wins.** So the rule is: **`core` states the `min` behaviour with `mkDefault`;
`gui` states its own with a plain value.**

Every `lsp.enable` in `core/languages.nix` is `lib.mkDefault false` for this
reason, and so is `enableExtraDiagnostics`. A plain `false` there fails loudly
the first time `gui` disagrees — which is the good case. The bad case is a
`mkDefault` that nothing ever overrides: it looks deliberate and is just noise.

**`lsp.servers.<name>.cmd` needs `lib.mkForce`.** nvf sets `cmd` itself at normal
priority, so a plain assignment conflicts. This is why `gui/languages.nix:66-85`
is written the way it is; keep the `mkForce` when those blocks move into
per-language files.

## Lists concatenate — and that is where order leaks into the hash

`vim.augroups`, `vim.autocmds`, `vim.keymaps` and `vim.treesitter.queries` are
all `listOf`. They **concatenate in module order**, which is the aspect order in
the variant's list, then import-tree's depth-first alphabetical walk within an
aspect. That order is the order they are emitted into `init.lua`, and it reaches
the store path.

Consequences worth holding onto:

- **Merging two files into one reorders them.** Stage 1 merges `core/x` and
  `gui/x`; expect the store path to move and explain the diff rather than
  assuming it is innocent.
- **Renaming a file reorders it** relative to its siblings in the same aspect.
- **A list never conflicts.** Two files declaring an augroup with the same name
  is not an error — it emits the group twice.

By contrast, **`vim.extraPlugins` and `vim.luaConfigRC` are order-stable under
file moves.** `extraPlugins` is an attrset ordered by its `after` field;
`luaConfigRC` is a DAG (`dagOf lines`) resolved by entry name and
`entryBefore`/`entryAfter`, not by which file set it. Moving `luaConfigRC.dadbod`
to another file does not move it in the output; renaming the key does.

## `config` and `lib` inside `flake.modules.*` are nvf's, not flake-parts'

Inside `flake.modules.nvf.<aspect> = { … }` you are writing an nvf module. The
`config`, `lib`, `options` and `pkgs` in scope there belong to nvf's evaluation.
To reach a flake-parts value, capture it in an outer `let` over the file's own
arguments. Getting this wrong produces infinite recursion, not a clear error.

## Things that fail silently rather than loudly

- **`flake.modules` is an open attrset.** `flake.modules.nvf.Gui` type-checks, is
  read by nobody, and drops its modules in silence. The generator's explicit
  aspect-name check is what catches it — keep it.
- **`pkgs` is not stock.** `flake.nix:16-22` carries an `allowUnfreePredicate`
  for `vscode-extension-ms-dotnettools-csharp`. Lose it and the failure surfaces
  as an unfree refusal from inside the roslyn closure, nowhere near the line that
  dropped it.
- **`min` resolves rustfmt and clang-format from `$PATH` on purpose**
  (`min/default.nix`), because pinning them drags ~2.4 GB and ~2.1 GB of
  toolchain into the closure. A `core` line that pins a formatter binary
  silently undoes that. Check the closure size, not just the build.
- **`preferPath` degrades quietly.** It execs the `$PATH` binary if present and
  the pinned one otherwise, so a broken devshell version wins over a working
  pinned one with no diagnostic.
- **An aspect's contents are only evaluated by variants that take it.** A type
  error inside `gui` cannot break `min`. Conversely `verify.sh build` passing on
  `min` says nothing about `gui`; build both.
- **Every *file* is evaluated once**, so a syntax error anywhere breaks both
  builds regardless of which aspect it declares.

## Eval-time vs config-time

`lib.mkIf` gates the *value* but still evaluates it. Guard the reference, not
just the config — exclude by attribute (`lib.optionalAttrs`), not by value
(`lib.mkIf`), whenever the excluded branch names a package that may not exist.

## Debugging

- **Bisect eval errors** by temporarily renaming a file to `_name.nix` —
  `import-tree` skips any path matching `/_`. Halve the tree until the build
  recovers. Undo before committing.
- **Inspect a merged aspect:** `nix repl` → `:lf .` →
  `config.flake.modules.nvf.gui`.
- **Read the generated config:** `nix build .#gui` then look inside
  `result/` — the assembled `init.lua` is the ground truth for every ordering
  question above.
