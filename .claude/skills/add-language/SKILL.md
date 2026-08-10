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
override — `csharp.nix` is the only one that doesn't, because roslyn-ls is a
dotnet assembly nobody has on `$PATH`.

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
- **Do not pin a formatter in `core`.** It resolves all of them from `$PATH` on
  purpose (`modules/formatter.nix`) — `min` is opened from inside `nix develop`,
  and rustfmt or clang-format alone pins ~2 GB into it. A new language's
  formatter goes in that file as `<name>.command = lib.mkForce "<name>"`, plus a
  `preferPathExe` fallback in its `gui` half at `lib.mkOverride 40`. Check the
  closure, not just the build.
- **Some languages need an indent autocmd.** C# has one because treesitter ships
  no indent queries for it (`modules/auto-cmds.nix:32-43`). If indentation is
  wrong in practice, this is why.

## Removing a language

Delete the file — then grep the language name *and* the server name across the
tree, because `defaults.nix`, `modules/auto-cmds.nix` and `modules/formatter.nix`
can still mention it and none of them live in `languages/`.

## Verify

```bash
./scripts/verify.sh build             # all three outputs build
./scripts/audit-path-resolution.sh    # nothing pinned that should resolve from $PATH
nix build .#gui && nix run .#gui -- some-file.<ext>
```

Then in the editor: `:checkhealth`, `:LspInfo` (server attached), and a
format-on-save. **A language that builds and does not attach is the normal
failure**, and no Nix-level check catches it.

`audit-path-resolution.sh` checks that `min` bundles no tool, that its
formatters are bare, that every `gui` server and formatter is wrapped, and that
neither closure grew. **Add the new tool to its `MIN_FORBIDDEN` list** — the
script cannot know a name nobody has told it, and the closure ceiling is only a
backstop.

## What the audit cannot check

Four things it is blind to, each of which has already cost this repo a bug.
Confirm them by hand:

- **Does a plugin, not nvf, own the server's activation?** nvf's rust module
  drives rustaceanvim, which starts rust-analyzer itself and merges
  `vim.lsp.config` over its own table. Leaving `enable` at its default `true`
  there gave a *second* client, invisible to any static check and to the build.
  On a live buffer: `:lua =#vim.lsp.get_clients()`. One is correct.
- **Does the server need args, and are they outside the wrapper?** `--stdio` and
  friends belong in the `cmd` list after the wrapper path, never inside it —
  `basedpyright` and `typescript-language-server` are the two exemplars. The
  audit sees a wrapped `cmd[0]` and asks nothing about the rest.
- **Is a wrapper pointless for this server?** roslyn-ls is a dotnet assembly
  launched with five args through a raw Lua `cmd`; nobody has it on `$PATH`. If
  so, add it to `UNWRAPPED_SERVERS` with the reason, so the exemption is
  recorded rather than looking like the gap it replaced.
- **Would the `gui` fallback drag a toolchain?** `rustfmt` and `csharpier` stay
  bare in both builds because their fallbacks cost ~2.4 GB and ~700 MiB. Measure
  before adding one; if it stays bare, add it to `GUI_BARE_FORMATTERS` and say
  why in `docs/decisions/formatters.md`.

## Before you finish

- One file, both aspects, `lsp.servers.<name>.cmd` included.
- `lib.mkDefault` in `core`, plain value in `gui`, `lib.mkForce` on any `cmd`.
- `./scripts/audit-path-resolution.sh` is green, and the new tool is in its
  `MIN_FORBIDDEN` list rather than merely absent from `min` today.
- The four it cannot check, confirmed by hand — one client on a live buffer,
  args outside the wrapper, exemptions recorded, fallback measured.
- Small, single-concern commit. Rationale in the message, not in comments.
- If the change touched a file listed under CLAUDE.md §8, migrate it in the same
  change or say why not.
