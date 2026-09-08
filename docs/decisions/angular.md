# decisions/angular

## The language module keeps lsp off

**Why:** `vim.languages.angular.enable` is on for the `angular` grammar and for
routing `htmlangular` to prettier; only `lsp.enable` is off, and no aspect turns
it on. The LSP half of nvf's module is broken twice at the pinned rev
(`59b0dc3`, and still on nvf `main` on 2026-09-08): its second `servers`
definition spells the name `angular-language-serve`, declaring a phantom server
that nvf enables with no `cmd`, and its conform routing sits behind
`mkIf (format.enable && !lsp.enable)`, so switching the LSP on through the
module deletes `formatters_by_ft.htmlangular`. `dev` enables
`vim.lsp.presets.angular-language-server` directly instead — the preset the
module would have reached — and writes the `filetypes` the module was trying to.

**Breaks:** loudly at eval, and that is the point: as in
`kotlin-lsp.md#the-built-in-module-keeps-everything-except-the-server`, the
`false` is plain rather than `lib.mkDefault false` because nothing is meant to
override it, so a `dev` line `languages.angular.lsp.enable = true` is a
definition conflict. "Normalising" both halves to the standard shape —
`mkDefault false` in `core`, `true` in `dev`, the preset line dropped — builds
cleanly and then fails three times in silence, measured 2026-09-08 against
`full`: Neovim's `can_start` drops the phantom for its missing `cmd` with one
`invalid "angular-language-serve" config` line in `lsp.log` and nothing in
`:messages`; the real server never reaches `.ts` buffers, because the
`typescript` filetype was on the phantom; and `htmlangular` loses its
formatter — `formatters_by_ft.htmlangular` is `nil`, `:ConformInfo` on a
template lists none, and `:w` leaves it as typed.

**Also:** the server's `cmd` is the preset's `getExe
pkgs.angular-language-server`, untouched — the one server here not routed
through `preferPathExe`. nixpkgs wraps `ngserver` with `--tsProbeLocations <its
typescript> --ngProbeLocations <its own node_modules>`, and the server honours
the first occurrence of each flag, so a `$PATH` `ngserver` would run without the
probes the wrapper supplies, and the pinned one cannot be pointed at a project's
TypeScript by appending flags either. Accepted: templates are served in any
workspace, at nixpkgs' TypeScript rather than the project's. When upstream fixes
the typo and lifts the formatter gate, `lsp.enable` can take the standard shape
and the preset line goes.

## Only an angular workspace roots the server

**Why:** the preset's `root_markers` are `["angular.json" "nx.json"]`. `nx.json`
says Nx, not Angular — an Nx monorepo may hold no Angular at all — and the
decision here is that only an `angular.json` makes a workspace Angular; an Nx
workspace without one is deliberately unserved. The list is forced to
`["angular.json"]`, and `workspace_required = true` is what turns "no marker
found" into "do not start": without it `vim.lsp.start` falls back to
single-file mode and, with `typescript` in `filetypes`, the server would attach
to every TypeScript buffer on the machine.

**Breaks:** silently, in the one direction that looks like a cleanup.
`root_markers` is `nullOr (listOf str)`, so dropping the `lib.mkForce` does not
error — the two lists concatenate and `nx.json` is back, with nothing in the
build to say so. `:lua =vim.lsp.config["angular-language-server"].root_markers`
is the check; one entry is correct.

**Also:** `workspace_required` restates the preset's value — two equal freeform
values merge — so the half of the gate that stops single-file mode lives in this
repo rather than in nvf's pin. `filetypes` is the module's `htmlangular` plus
the `typescript` its typo failed to add; it is also the blast-radius limit
`prefer-path.md#rustaceanvim-owns-activation` describes, since a config without
`filetypes` matches every buffer under the workspace.

## Every html file in an angular workspace is a template

**Why:** Neovim never names `htmlangular` by file name — the `*.component.html`
rule in `filetype/detect.lua` is commented out upstream — and only sniffs the
first forty lines for control flow (`@if`, `*ngIf`, `<ng-template>` …). A
template using none of those, and every Angular 20-style `app.html`, stays
`html`: the html grammar loads instead of angular, superhtml attaches, and the
server, whose `filetypes` are `htmlangular` and `typescript`, never does. The
`vim.filetype.pattern` entry in `modules/languages/angular.nix` runs before the
extension table (a user pattern defaults to priority 0) and returns
`htmlangular` for any `*.html` with an `angular.json` above it; returning
nothing elsewhere lets Neovim's own detection carry on.

**Breaks:** silently. Delete it and a control-flow-free template goes back to
`html` — superhtml attaches, the Angular server does not, highlighting is the
html grammar's — with no error anywhere. Measured 2026-09-08 in a scratch
workspace holding only `nx.json`: `app.html` opens as `html` with superhtml
attached and the Angular server absent, which is exactly the state this entry
prevents inside an `angular.json` workspace.

**Also:** `index.html` and any other non-template html under the workspace
become `htmlangular` too; the server has nothing to say about them and prettier
still formats them, so it is harmless. superhtml *not* attaching to templates is
a feature — its strictness
(`data-languages.md#html-uses-superhtml-for-lsp-only`) is wrong for template
syntax. Formatting rides on `formatters_by_ft.htmlangular`, which nvf's module
writes only while `lsp.enable` is off (first entry). prettier picks its
`angular` parser from the file name for `*.component.html` only — measured
2026-09-08, `app.html` infers `html` — so a workspace that names templates
`app.html` wants a `.prettierrc` override of its own (`overrides: [{ files:
"*.html", options: { parser: "angular" } }]`), a project setting rather than
this config's.