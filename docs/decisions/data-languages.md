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
