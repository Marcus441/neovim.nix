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
| `enable`, treesitter, formatter | `core` | `modules/languages.nix`, `core` half | `modules/languages/<lang>.nix` |
| `lsp.enable = lib.mkDefault false` | `core` | `modules/languages.nix`, `core` half | same file |
| `lsp.enable = true`, `servers`, extensions | `gui` | `modules/languages.nix`, `gui` half | same file |
| `lsp.servers.<name>.cmd` override | `gui` | `modules/languages.nix`, separate block below the `gui` half | same file |
| filetype/indent autocmd | `core` | `modules/auto-cmds.nix`, `core` half | same file, or the language file |
| treesitter query patch | `core` | `modules/languages.nix`, `core` half | same file |

**One file already, but three places inside it.** The `lsp.servers.*.cmd` block
is the one that gets forgotten — it sits below the `gui` half and never names
the language. Scroll to the bottom of the file before declaring done.

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
  `modules/languages.nix:65` — it execs the `$PATH` binary if present, else the pinned
  one. Use it for anything a devshell plausibly provides. It is a `let` binding
  in that file today, so a language file split out before Stage 2 cannot reach
  it (CLAUDE.md §8 item 6).
- **Do not pin a toolchain-sized formatter.** `core` resolves rustfmt and
  clang-format from `$PATH` on purpose (`modules/formatter.nix`) — each
  pins ~2 GB into `min`.
  Check the closure, not just the build.
- **Some languages need an indent autocmd.** C# has one because treesitter ships
  no indent queries for it (`modules/auto-cmds.nix:32-43`). If indentation is wrong
  in practice, this is why.

## Removing a language

Every site above, in one commit. `8dc5394` is the worked example: it removed
kotlin from both halves together, back when they were two files. Grep the
language name and the server name across the tree before committing — the
`lsp.servers` block does not mention the language.

## Verify

```bash
./scripts/verify.sh build     # both outputs build
nix build .#gui && nix run .#gui -- some-file.<ext>
```

Then in the editor: `:checkhealth`, `:LspInfo` (server attached), and a
format-on-save. **A language that builds and does not attach is the normal
failure**, and no Nix-level check catches it.

## Before you finish

- Both halves of `modules/languages.nix` updated, plus the `lsp.servers` block.
- `lib.mkDefault` in `core`, plain value in `gui`, `lib.mkForce` on any `cmd`.
- Small, single-concern commit. Rationale in the message, not in comments.
- If the change touched a file listed under CLAUDE.md §8, migrate it in the same
  change or say why not.
