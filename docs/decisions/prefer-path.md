# decisions/prefer-path

## Silent fallback

**Why:** `preferPathExe` wraps a language server in a shell script that execs
the `$PATH` binary when one exists and the pinned one otherwise. It exists so a
project's own toolchain wins inside a devshell — the pinned server is the floor,
not the ceiling.

**Breaks:** silently, by design. A broken or stale `$PATH` binary beats a
working pinned one with no diagnostic anywhere: the wrapper cannot tell a
deliberate devshell override from an accident, so it does not try. Symptom is a
language server that misbehaves only inside one project. `command -v <name>` in
that directory is the check.

**Also:** the option is declared `functionTo raw` and takes `pkgs` explicitly
because the top-level flake-parts `config` is not per-system; a language file
reaches it by capturing `config` in an outer `let`. Weak typing is the accepted
cost of that shape, chosen over a `/_` expression so no language file carries a
relative import path. See `docs/conventions/overrides.md` for the `mkForce` that
every `lsp.servers.*.cmd` needs alongside it.
