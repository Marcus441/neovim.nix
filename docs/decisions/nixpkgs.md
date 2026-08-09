# decisions/nixpkgs

## allowUnfreePredicate

**Why:** `modules/nixpkgs.nix` instantiates `pkgs` itself so it can carry an
`allowUnfreePredicate` for `vscode-extension-ms-dotnettools-csharp`. The C#
stack uses roslyn, and roslyn's language server is packaged from the unfree
VS Code extension. Nothing else in the tree is unfree, and the predicate names
that one package rather than setting `allowUnfree = true`.

**Breaks:** silently. Drop the predicate, or let something else supply `pkgs`,
and `min` keeps building — only `gui` fails, with an unfree refusal raised from
inside the roslyn closure, nowhere near the line that dropped it. The `pkgs`
every language file receives is this one; there is no second instantiation to
fall back on.

**Also:** migrating C# off roslyn would remove the need for this, and is listed
under *Deliberately deferred* in `.claude/rules/settled-decisions.md` — it is not
a cleanup to offer unasked.
