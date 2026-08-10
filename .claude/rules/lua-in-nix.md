---
paths: "modules/**/*.nix"
---

# Lua inside Nix

Most `''` blocks in this repo hold **Lua**, and everything in one ships verbatim
into the generated `init.lua`. Text there is content, not source commentary.

## The three ways Lua gets in

| Mechanism | Type | Use for |
| --- | --- | --- |
| `lib.mkLuaInline ''…''` | raw Lua expression | an autocmd `callback`, a keymap `action` that must be a function |
| `vim.luaConfigRC.<name> = ''…''` | DAG entry | a plugin's setup body |
| `vim.extraPlugins.<n>.setup` | string | setup for a plugin nvf has no module for |

`mkLuaInline` emits the text **as an expression**, not as a quoted string — so
its content must be a valid Lua expression (usually `function() … end`), and a
stray trailing statement is a syntax error in `init.lua`, discovered at Neovim
start rather than at build time.

A large body belongs in a `.lua` file read with `builtins.readFile`
(`modules/kanagawa.nix:6` does this for the kanagawa setup). `import-tree`
imports `.nix` only, so the `.lua` file needs no `/_` prefix.

## The escaping traps

- **`${` in Lua must be written `''${`.** Otherwise Nix interpolates it. A Lua
  string containing `${…}` is the common case.
- **A `'' `sequence inside Lua must be written `'''`.** Two adjacent single
  quotes close the block.
- **An interpolation at column 0 reindents the whole block.** `''` strips the
  least-indented line's indentation, and a line beginning `${…}` has none — so
  one flush-left interpolation flattens everything around it. Indent it.

## A comment inside a `''` block moves a store path

A `--` line in a `''` block is Lua that ships into `init.lua`. Adding, removing
or rewording one changes the output derivation. So:

- **Label what the block produces; never argue for a value.** A label lets a
  reader skip the block. An argument belongs in `docs/`.
- **Two lines is the cap.** A third means it is an argument. A PostToolUse hook
  enforces the cap across `--`, `--[[ ]]`, `#`, `//` and `/* */`.
- A one-line note like `-- The keep function is embedded directly within the Lua
  string` (`modules/macro-recording.nix:16`) is fine — it explains why the shape
is odd.

The cap does not apply to Nix comments *outside* a `''` block. Those are governed
by CLAUDE.md §10: one `# load-bearing: docs/decisions/<area>.md#anchor` pointer,
or nothing.

## Ordering

`luaConfigRC` is a DAG keyed by entry name, resolved with `entryBefore` /
`entryAfter`. **File position does not affect it** — moving
`luaConfigRC.dadbod` between files leaves the output identical; renaming the key
does not. `extraPlugins` is likewise ordered by its `after` field, and that field
resolves **across files** — `modules/undo.nix` puts `undotree` after the
`theme-plugin` that `modules/kanagawa.nix` declares, and neither file's
position matters.

This is the opposite of `vim.autocmds` and friends, which are lists ordered by
module position. See `evaluation-hazards.md`.

## Lua that reads the outside world

`modules/database.nix` reads `$NVIM_DB_SECRETS` or
`~/.config/nvim-secrets/servers.json` and shells out to `sqlcmd`. Two standing
consequences: the build succeeds on a machine with neither, and the failure is a
silently empty `vim.g.dbs`. Do not add a second thing of this shape without
saying so — a config that half-works is worse than one that reports.
