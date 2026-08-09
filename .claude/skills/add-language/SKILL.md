---
description: >-
  Use when adding, removing, or fixing a programming language in the Neovim
  config — treesitter, formatter, LSP server, diagnostics extensions, filetype
  autocmds, or a lua-language-server-style cmd override. Covers every place a
  language currently reaches, the mkDefault/mkForce rules, and verification.
---

# Adding a language

A language reaches up to five places. Missing one is how the kotlin attempt
burned seven commits (`9f20108`–`8dc5394`) — each fix found one more site.

## Where it goes

| What | Aspect | Today | After Stage 2 |
| --- | --- | --- | --- |
| `enable`, treesitter, formatter | `core` | `core/languages.nix` | `modules/languages/<lang>.nix` |
| `lsp.enable = lib.mkDefault false` | `core` | `core/languages.nix` | same file |
| `lsp.enable = true`, `servers`, extensions | `gui` | `gui/languages.nix` | same file |
| `lsp.servers.<name>.cmd` override | `gui` | `gui/languages.nix` (separate block) | same file |
| filetype/indent autocmd | `core` | `core/auto-cmds.nix` | same file, or the language file |
| treesitter query patch | `core` | `core/languages.nix` | same file |

**After Stage 2 this is one file.** Until then it is two, and the second one is
the one that gets forgotten — check `gui/languages.nix` before declaring done.

## The rules that bite

- **`core` writes `lsp.enable = lib.mkDefault false`; `gui` writes plain
  `true`.** A plain `false` in `core` is a definition conflict the moment `gui`
  disagrees. `mkDefault` on both sides is the same error. See
  `.claude/rules/evaluation-hazards.md`.
- **`lsp.servers.<name>.cmd` needs `lib.mkForce`.** nvf sets `cmd` itself at
  normal priority; a plain assignment conflicts.
- **The `cmd` override is a separate block from the language block** — different
  option path (`vim.lsp.servers.*` vs `vim.languages.*`), and the server's
  attribute name is the *server's*, not the language's:
  `basedpyright` for python, `typescript-language-server` for typescript.
- **`preferPath` wraps a server so a project's own toolchain wins.**
  `gui/languages.nix:6` — it execs the `$PATH` binary if present, else the pinned
  one. Use it for anything a devshell plausibly provides. It is a `let` binding
  in that file today, so a language file split out before Stage 2 cannot reach
  it (CLAUDE.md §8 item 6).
- **Do not pin a toolchain-sized formatter in `core`.** `min` resolves rustfmt
  and clang-format from `$PATH` on purpose (`min/default.nix`) — each pins ~2 GB.
  Check the closure, not just the build.
- **Some languages need an indent autocmd.** C# has one because treesitter ships
  no indent queries for it (`core/auto-cmds.nix:31-42`). If indentation is wrong
  in practice, this is why.

## Removing a language

Every site above, in one commit. `8dc5394` is the worked example: it removed
kotlin from both `languages.nix` files together. Grep the language name and the
server name across the tree before committing — the `lsp.servers` block does not
mention the language.

## Verify

```bash
./scripts/verify.sh build     # both outputs build
nix build .#gui && nix run .#gui -- some-file.<ext>
```

Then in the editor: `:checkhealth`, `:LspInfo` (server attached), and a
format-on-save. **A language that builds and does not attach is the normal
failure**, and no Nix-level check catches it.

## Before you finish

- Both `languages.nix` files updated, or one file after Stage 2.
- `lib.mkDefault` in `core`, plain value in `gui`, `lib.mkForce` on any `cmd`.
- Small, single-concern commit. Rationale in the message, not in comments.
- If the change touched a file listed under CLAUDE.md §8, migrate it in the same
  change or say why not.
