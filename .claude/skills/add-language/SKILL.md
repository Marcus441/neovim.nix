---
description: >-
  Use when adding, removing, or fixing a programming language in the Neovim
  config — treesitter, formatter, LSP server, diagnostics extensions, filetype
  autocmds, or a lua-language-server-style cmd override. Covers every place a
  language currently reaches, the mkDefault/mkForce rules, and verification.
---

# Adding a language

**One language is one file: `modules/languages/<lang>.nix`.** That is what `45334ab`
bought, and the kotlin attempt (`9f20108`–`8dc5394`, seven commits, each fix
finding one more site) is what it cost before.

## The template

`modules/languages/rust.nix` is the one to copy — it is the only shape that
exercises every part:

```nix
{config, ...}: let
  inherit (config) preferPathExe;
in {
  flake.modules.nvf.core = {lib, ...}: {
    vim.languages.rust = {
      enable = true;
      lsp.enable = lib.mkDefault false;
    };
  };

  flake.modules.nvf.gui = {pkgs, lib, ...}: {
    vim = {
      languages.rust = {
        lsp.enable = true;
        extensions.crates-nvim.enable = true;
      };

      lsp.servers.rust-analyzer.cmd = lib.mkForce [
        (preferPathExe pkgs "rust-analyzer" (lib.getExe pkgs.rust-analyzer))
      ];
    };
  };
}
```

Drop the outer `{config, ...}: let … in` when the language needs no `cmd`
override — `nix.nix` and `csharp.nix` are the two that don't.

| What | Aspect | Where |
| --- | --- | --- |
| `enable`, treesitter, formatter | `core` | the language file |
| `lsp.enable = lib.mkDefault false` | `core` | the language file |
| `lsp.enable = true`, `servers`, extensions | `gui` | the language file |
| `lsp.servers.<name>.cmd` override | `gui` | the language file |
| treesitter query patch | `core` | the language file (`clang.nix` has the cpp one) |
| `enableFormat` / `enableTreesitter` / `enableExtraDiagnostics` | both | `languages/defaults.nix` — language-wide, do not touch per language |
| filetype/indent autocmd | `core` | `modules/auto-cmds.nix` today; the language file is defensible |

## The rules that bite

- **`core` writes `lsp.enable = lib.mkDefault false`; `gui` writes plain
  `true`.** A plain `false` in `core` is a definition conflict the moment `gui`
  disagrees. `mkDefault` on both sides is the same error. See
  `.claude/rules/evaluation-hazards.md`.
- **`lsp.servers.<name>.cmd` needs `lib.mkForce`.** nvf sets `cmd` itself at
  normal priority; a plain assignment conflicts.
- **The `cmd` override sits at a different option path** (`vim.lsp.servers.*`,
  not `vim.languages.*`) and is keyed by the *server's* name, not the language's:
  `basedpyright` for python, `typescript-language-server` for typescript. It is
  still in the same file — that is the whole point.
- **`preferPathExe` wraps a server so a project's own toolchain wins.** It execs
  the `$PATH` binary if present, else the pinned one. Use it for anything a
  devshell plausibly provides. It is a flake-parts option
  (`modules/prefer-path.nix`), so **capture it in an outer `let` over the file's
  own arguments** — inside `flake.modules.*`, `config` is nvf's — and **pass
  `pkgs` as its first argument**.
- **Do not pin a toolchain-sized formatter.** `core` resolves rustfmt and
  clang-format from `$PATH` on purpose (`modules/formatter.nix`) — each pins
  ~2 GB into `min`. Check the closure, not just the build.
- **Some languages need an indent autocmd.** C# has one because treesitter ships
  no indent queries for it (`modules/auto-cmds.nix:32-43`). If indentation is
  wrong in practice, this is why.

## Removing a language

Delete the file — then grep the language name *and* the server name across the
tree, because `defaults.nix`, `modules/auto-cmds.nix` and `modules/formatter.nix`
can still mention it and none of them live in `languages/`.

## Verify

```bash
./scripts/verify.sh build     # all three outputs build
nix build .#gui && nix run .#gui -- some-file.<ext>
```

Then in the editor: `:checkhealth`, `:LspInfo` (server attached), and a
format-on-save. **A language that builds and does not attach is the normal
failure**, and no Nix-level check catches it.

## Before you finish

- One file, both aspects, `lsp.servers.<name>.cmd` included.
- `lib.mkDefault` in `core`, plain value in `gui`, `lib.mkForce` on any `cmd`.
- Small, single-concern commit. Rationale in the message, not in comments.
- If the change touched a file listed under CLAUDE.md §8, migrate it in the same
  change or say why not.
