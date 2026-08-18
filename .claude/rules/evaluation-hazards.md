---
paths: "modules/**/*.nix"
---

# Evaluation hazards

## Overriding across aspects is the central mechanic

`core` and `dev` are merged into one nvf evaluation. Where both set the same
key, the module system's priorities decide, and only one combination works:

| `core` says | `dev` says | Result |
| --- | --- | --- |
| `lib.mkDefault false` | `true` | **dev wins.** The intended shape. |
| `false` | `true` | **Error** — two definitions at the same priority, no merge for a bool. |
| `lib.mkDefault false` | `lib.mkDefault true` | **Error** — same priority again. |
| `lib.mkForce false` | `true` | core wins. Almost always a mistake. |

Priorities: `mkDefault` = 1000, a plain value = 100, `mkForce` = 50. **Lower
wins.** So the rule is: **`core` states the `min` behaviour with `mkDefault`;
`dev` states its own with a plain value.**

Every `lsp.enable` in the `core` half of a `modules/languages/*.nix` is `lib.mkDefault false` for this
reason, and so is `enableExtraDiagnostics`. A plain `false` there fails loudly
the first time `dev` disagrees — which is the good case. The bad case is a
`mkDefault` that nothing ever overrides: it looks deliberate and is just noise.

**`lsp.servers.<name>.cmd` needs `lib.mkForce`.** nvf sets `cmd` itself at normal
priority, so a plain assignment conflicts. This is why every `lsp.servers.*.cmd`
in `modules/languages/` carries one.

## Lists concatenate — and that is where order leaks into the hash

`vim.augroups`, `vim.autocmds`, `vim.keymaps` and `vim.treesitter.queries` are
all `listOf`. They **concatenate in module order**, which is the aspect order in
the variant's list, then import-tree's depth-first alphabetical walk within an
aspect. That order is the order they are emitted into `init.lua`, and it reaches
the store path.

Consequences worth holding onto:

- **Merging two files into one need not reorder them, and predicting either way
  is the mistake.** `094bc3e` merged the `core`/`gui` pairs and flattened both
  profile directories, and all three store paths were unchanged: **only the
  relative order of files contributing to the *same* aspect matters**, and each
  aspect's sequence was alphabetical before the move and after it. Interleaving
  the two sequences moved every file and permuted nothing. A merge that lands a
  file on the other side of a same-aspect sibling *does* reorder. Build both.
- **Renaming a file reorders it** relative to its siblings in the same aspect.
- **A list never conflicts.** Two files declaring an augroup with the same name
  is not an error — it emits the group twice.
- **A plugin's `setupOpts` lists concatenate against nvf's own defaults.**
  `blink-cmp`'s `sources.default` holds ours and nvf's end to end today. Where
  the option is a keymap, whichever definition comes first is what the key
  *does*, so **reordering files can change behaviour without changing any Lua
  body**: `2ea202f` flipped `keymap."<C-d>"` this way, and `03123e9` resolved it
  by dropping our blink keymap overrides rather than letting file order decide.

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
- **`pkgs` is not stock.** `modules/nixpkgs.nix` carries an `allowUnfreePredicate`
  for `vscode-extension-ms-dotnettools-csharp`. Lose it and the failure surfaces
  as an unfree refusal from inside the roslyn closure, nowhere near the line that
  dropped it.
- **`core` resolves every formatter from `$PATH` on purpose**
  (`modules/formatter.nix`), because pinning rustfmt and clang-format drags
  ~2.4 GB and ~2.1 GB of toolchain into `min`, and prettier alone drags 190 MiB
  of `nodejs`. A line that pins a formatter binary silently undoes that. Check
  the closure size, not just the build. `dev` puts each back as a `preferPathExe`
  fallback, and because `core` already spent `mkForce` there, **`dev` must use
  `lib.mkOverride 40`** — a second `mkForce` is a conflict, and a plain value
  silently loses.
- **`preferPath` degrades quietly.** It execs the `$PATH` binary if present and
  the pinned one otherwise, so a broken devshell version wins over a working
  pinned one with no diagnostic.
- **An aspect's contents are only evaluated by variants that take it.** A type
  error inside `dev` cannot break `min`. Conversely `verify.sh build` passing on
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
  `config.flake.modules.nvf.dev`.
- **Read the generated config:** `nix build .#gui` then look inside
  `result/` — the assembled `init.lua` is the ground truth for every ordering
  question above.
