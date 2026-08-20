# decisions/data-languages

## prettier everywhere

**Why:** nvf's own defaults would format JSON with `jsonfmt` and HTML with
`superhtml`, and each of those presets writes a store path into
`formatters.<name>.command`. `modules/formatter.nix` only forces the seven names
it lists back to a bare command, so an unlisted formatter arrives pinned — in
`core`, which means in `min`. Routing every data language to prettier instead
reuses a name that file already handles in both halves, so this change adds no
line to it at all.

**Breaks:** silently, and only in the direction that matters. Taking nvf's
default for one of these languages builds fine and formats fine; it just drags
that formatter's closure into the minimal editor, which is the failure
`formatters.md#path-resolution` exists to prevent. `jsonfmt` is 41.3 MiB of Go
and `superhtml` 3.1 MiB of Zig — small enough that nothing looks wrong.

**Also:** the cheap-looking alternative is worse than it reads. Adding `jsonfmt`
to `modules/formatter.nix` is not one line but two — the bare `mkForce` in
`core` and the `mkOverride 40` fallback in `dev` — plus a formatter nobody has
on `$PATH`, where prettier is already there for markdown and typescript.

## templates yaml becomes a gitlab filetype

**Why:** nvf's yaml module sets `vim.filetype.pattern` **unconditionally** —
outside every `mkIf` — mapping four patterns to the filetype `yaml.gitlab`. Two
are specific to GitLab CI; the other two are `templates/.*%.ya?ml` and
`templates/.*/template%.ya?ml`, which catch any Helm chart and any repo that
happens to keep YAML in a `templates/` directory. `gitlab-ci-ls` is not enabled
here, so nothing wanted that filetype, but it applies anyway. nvf maps
`yaml.gitlab` through for treesitter (`filetypeMappings`) and for the LSP (the
server's `filetypes` list). It does not map it through for conform, which routes
on `formatters_by_ft.yaml` alone.

**Breaks:** silently. Highlighting works, the LSP attaches, and `:w` on a chart
template simply does not format — conform finds no formatter for the filetype
and skips without a message. Removing the `formatters_by_ft."yaml.gitlab"` line
restores exactly that silence.

**Also:** the alternative was forcing the two broad patterns back to `yaml`,
which means restating an upstream default in order to disagree with it, and
breaking quietly if nvf renames or re-scopes them. Routing the filetype is
additive and survives a pin bump either way.

## scss declines some-sass

**Why:** nvf defaults `vim.languages.scss` to `some-sass-language-server`, which
is the better SCSS server — it resolves variables and mixins across files, where
the VSCode CSS server treats each buffer alone. It is also not in nixpkgs: nvf
builds it as one of its own flake packages, against **nvf's** nixpkgs rather than
this repo's. Measured 2026-08-20, that second `nodejs` costs **255.4 MiB**, where
pointing SCSS at `vscode-css-language-server` costs nothing at all — the CSS
server is already pinned, and `vscode-langservers-extracted` is one derivation
shipping the JSON, CSS, HTML and ESLint servers together.

**Breaks:** visibly, and `verify.sh` reports the number. Dropping the `servers`
line takes nvf's default back and the closure jumps by a quarter of a gigabyte
for one language's cross-file completion.

**Also:** this is the same trade `markdown.md#the-closure-cost-lands-in-dev-not-min`
made in the other direction — marksman is pinned at 95.5 MiB because it has no
substitute, and some-sass is declined because it has one that is already paid
for. If nixpkgs ever packages some-sass against this repo's nixpkgs, re-measure:
the objection is the duplicate nodejs, not the server.

## html uses superhtml for lsp only

**Why:** nvf's html module offers `superhtml`, `emmet-ls` and
`stimulus-language-server`, and defaults `format.type` to `superhtml` as well.
The VSCode HTML server is *not* in that enum, even though it ships in the
`vscode-langservers-extracted` this repo now pins for JSON and CSS — so the
server is superhtml by elimination, at 3.1 MiB. The formatter is prettier
because `core` must never name a store path
(`#prettier-everywhere`), and `superhtml` as the formatter would put one there.

**Breaks:** silently, in the `min` direction only — see `#prettier-everywhere`.
The LSP half is `dev`, so it cannot reach `min` however it is set.

**Also:** superhtml is strict about malformed markup by design; it reports errors
where a template engine's output would be fine. If a Jinja or Razor fragment is
noisy, that is the server, not a misconfiguration.

## the linters stay off

**Why:** `languages/every-language.nix` sets `enableExtraDiagnostics = true` in
`dev`, and nvf's scss and html modules each carry a default diagnostics provider
— `stylelint` and `htmlhint`. So enabling those two languages *opts in* to two
linters nobody asked for. `stylelint` exits with an error when a project has no
`.stylelintrc`, which is most of them, so its default state is a diagnostic that
is always wrong; `htmlhint` (6.1 MiB) is turned off beside it for symmetry
rather than for a cost.

**Breaks:** loudly, which is why these two lines are the plain `false` they look
like — the option's own default is `config.vim.languages.enableExtraDiagnostics`,
so an ordinary value overrides it and no `mkDefault` or `mkForce` is involved.
Deleting either line switches its linter on.

**Also:** this is the one place `dev`'s language-wide switch is a liability
rather than a convenience. Every language file added from here on inherits it,
so check whether the language nvf is enabling has a `defaultDiagnosticsProvider`
before assuming diagnostics are opt-in. `markdown.nix` is the opposite case —
it names `markdownlint-cli2` deliberately and routes its `cmd` through
`preferPathExe`, which is what enabling one properly costs.
