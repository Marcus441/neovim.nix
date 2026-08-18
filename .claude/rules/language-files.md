---
paths: "modules/languages/**,modules/formatter.nix"
---

# Language files — one language, every aspect it touches

**The procedure and the copyable template live in the add-language skill;
the priority mechanics live in `evaluation-hazards.md`.** Neither is restated
here — this file is what bites while a language file is open in front of you.

**One language is one file** (AGENTS.md §1 Inv. 3). The kotlin attempt
(`9f20108`–`8dc5394`) took seven commits because each fix found one more site;
`45334ab` is what ended that. The two lawful exceptions are the files this rule
also matches for that reason: `formatter.nix` carries every language's formatter
routing, and `languages/every-language.nix` carries the language-*wide*
switches — `enableFormat`, `enableTreesitter`, `enableExtraDiagnostics` — and
never a per-language line. **When removing a language, grep the language name
*and* the server name**: both files can still mention it and neither is named
after a language.

## The split inside one file

`core` gets `enable`, treesitter, formatter routing, and any filetype/indent
autocmd with its augroup; `gui` gets `lsp.enable = true`, `servers`, extensions
and `cmd` overrides (AGENTS.md §6). `core` writes `lsp.enable = lib.mkDefault
false`; `gui` writes a plain `true` — the only combination that merges.

**`lsp.servers.<name>` is keyed by the *server's* name, not the language's**
(`basedpyright`, not python), at a different option path — and stays in the
same file anyway; that is the point of Inv. 3. Its `cmd` needs `lib.mkForce`,
and `preferPathExe` is flake-parts config captured in an outer `let`
(`nvf-file-conventions.md`; `rust.nix` is the exemplar).

## Formatters: `min` is `$PATH`-only; `gui` may pin a fallback

**Never pin a formatter binary in `core`** — it resolves every one from `$PATH`
deliberately, and a pin silently drags a toolchain into `min`
(`docs/decisions/formatters.md`; rustfmt alone is ~2.4 GB). A new language's
formatter is two halves of `modules/formatter.nix`:

```nix
# core — name only, resolved from $PATH
<name>.command = lib.mkForce "<name>";
# gui — pinned fallback; mkOverride 40, not a second mkForce
<name>.command = lib.mkOverride 40 (preferPathExe pkgs "<name>" (lib.getExe pkgs.<name>));
```

The `gui` half is optional per formatter — `rustfmt` deliberately has none
(`settled-decisions.md`). Check the closure, not just the build.

## These files are the densest `# load-bearing:` carriers

`csharp.nix` holds eight, `kotlin.nix` six, `nix.nix` five, `rust.nix` and
`formatter.nix` two each. Changing a marked value changes its docs entry in the
same commit (AGENTS.md §10), and a new exception earns a pointer plus an entry.

## Verify

**The normal failure is a language that builds and does not attach** — no
Nix-level check catches it. `./scripts/verify.sh build`, then `:LspInfo` and a
format-on-save in the editor the change was for.
