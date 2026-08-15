# CLAUDE.md — nvf configuration, dendritic

This repository follows **the dendritic pattern** — every Nix file is a
flake-parts module organized by feature, not by which build it belongs to. If a
change would violate an invariant, stop and say so; the invariants are the whole
value of this structure, and a single exception metastasises. The refactor that
got here is finished (`2ea202f`…`24e4cc7`), so §1 describes the tree as it is and
§8 is empty. Rationale for individual values lives in `docs/`, reached by a
`# load-bearing:` comment.

| Output | Aspects | Consumed by |
| --- | --- | --- |
| `min` | `core` | `home.packages` on every host |
| `default` | `core` | alias of `min` |
| `gui` | `core` `gui` | `programs.neovide.settings.neovim-bin` |

Two derivations, three output names. **The names are public API** —
`~/.dotfiles/flake` pins `github:Marcus441/neovim.nix` and reads
`packages.${system}.min` and `.gui`, so renaming one breaks the desktop. **Local
edits do not reach the machine:** that flake pins a GitHub revision, not this
working tree, and moving the pin is the human's call, not yours.

## 1. Invariants

1. **Every `.nix` file under `modules/` is a flake-parts module.** One
   interpretation, always — not an nvf module, not a package expression.
2. **`flake.nix` is a manifest.** Inputs + `mkFlake` + `import-tree`, no
   configuration logic. Edited only to add an input.
3. **One file = one concern, across every aspect it touches.** One file
   declaring both `core` and `gui` is the merge working as intended.
4. **File paths name the feature but carry no system-meaning.** Never a variant,
   never an aspect. Directories are navigation, not structure.
5. **No manual import lists** except the variant wiring. `import-tree` finds the rest.
6. **Aspects are variant-agnostic.** Per-build facts live in the variant record.
7. **`default`, `min` and `gui` are public API.** Adding an output is an API
   addition; renaming one is a breaking change.

Full prose, exemplars, the directory test: `.claude/rules/nvf-file-conventions.md`.

## 2. Mental model

flake-parts is the *top-level configuration*; every file participates in one
evaluation. nvf modules are not imported from paths — they are **option values**
under `flake.modules.nvf.<aspect>`, typed `deferredModule`, and those attrsets
**merge**, both ways: **many files → one aspect** (grow a feature by adding a
file, never editing a list) and **one file → many aspects** (the direction that
gets forgotten). The unit of **concern** is the *file*, of **applicability** the
*aspect*; neither contains the other. There is **one class** here (`nvf`), not
the sibling flake's three, so nothing but the aspects keeps files honest.

## 3. Aspects

An aspect is a **decision or a capability**, never a magnitude and never a build
name. **An aspect earns its existence when some variant says no.** With two variants,
exactly one declining aspect is earned, and it is `gui`. Everything else is
`core`. Files still decompose freely by concern — `modules/languages/rust.nix`
declares both memberships — but a third aspect needs a third variant to decline
it, or it is structure without a decision behind it.

Good, when earned: `gui`, `db`, `neovide`. Bad: `minimal`, `extras`, `heavy` —
magnitude names rot; `terminal`, `ide` — a build archetype, and the archetype is
the *list*. When a third variant appears, split `gui` at the seam *that variant*
declines and put the new names where `gui` sat (§5). Until then, do not pre-split.

## 4. Layout

Descriptive, not normative. `import-tree` does not care where any file lives.

```
modules/
  aspects.nix                # declares flake.modules and aspectRequires options
  variants/generator.nix     # the ONE permitted central wiring point
  variants/<name>.nix        # what a build IS: an aspect list
  <concern>.nix              # declares its own aspect membership
  languages/<lang>.nix       # one language, every aspect it touches
  **/_*                      # .nix files that are NOT modules — import-tree skips them
```

A directory is permitted when its name does not predict the aspect of every file
inside: `languages/` is fine, a `gui/` holding only `gui` files is not. §9 lists
the prohibited shapes.

`import-tree` imports **`.nix` files only** — a `.lua`, `.json` or `.md` asset
sits at any ordinary path and is read with `builtins.readFile`. `/_` is for
`.nix` files that are *not* modules (expressions, derivations, dormant code);
**it is not a grouping mechanism.**

## 5. Ordering and store paths

Order is the one thing here that reaches a derivation hash: **nvf's list options
concatenate in module order**, and that becomes the order of the generated
`init.lua`.

- `vim.augroups`, `vim.autocmds`, `vim.keymaps`, `vim.treesitter.queries` are
  **lists**. Merging two files into one, or renaming a file so it sorts
  differently, reorders them.
- **A plugin's `setupOpts` lists concatenate too**, against *nvf's own defaults*
  and not just yours. Where a key is defined twice, module order picks the
  runtime winner: `2ea202f` flipped `keymap."<C-d>"` that way, `03123e9` fixed it.
- `vim.extraPlugins` is an attrset keyed by name — order comes from `after`, not
  from file order.
- **A file's position in the emitted config is not the alphabetical order you
  would guess.** Measured, it is the reverse. Never predict it.
- **Aspect order in a variant's list is load-bearing.** Splitting an aspect? Put
  the new names where the old one sat.
- **Only the relative order of files contributing to the same aspect matters.**

A working model, not a mechanism. **Measure; do not predict** — recipe in
`.claude/rules/structural-verification.md`.

## 6. Which aspect a line belongs to

| Goes in `core` | Goes in `gui` |
| --- | --- |
| options, keymaps that work without a server | LSP servers, `lsp.*`, diagnostics extensions |
| treesitter, formatters, `languages.<x>.enable` | completion, dashboard, session, statusline |
| theme, clipboard, oil, snacks picker | anything that assumes Neovide or a big closure |

**Default to `core`. Justify the exception.** `min` ships to every host; `gui` is
one program's launcher, so a line in `gui` that could have been `core` is a line
the terminal editor does without for no reason. The counter-pressure is closure
size: `core` resolves **every** formatter from `$PATH` rather than pinning one,
because `min` is opened from inside `nix develop` and rustfmt and clang-format
alone drag ~2 GB each (`docs/decisions/formatters.md`). **A `core` line that
pulls a toolchain into `min` is what justifies `gui`.**

## 7. Hazards and verification

- **Every *file* is evaluated once** — a syntax error anywhere breaks both
  builds. But an **aspect's contents are only evaluated by variants that take it.**
- **`core` sets `lib.mkDefault false`; `gui` overrides with a plain value.** The
  only combination that merges, and this repo's sharpest edge —
  `docs/conventions/overrides.md`, `.claude/rules/evaluation-hazards.md`.
- **`config` inside `flake.modules.*` is nvf's, not flake-parts'.**
- **`pkgs` here is not stock.** It carries an `allowUnfreePredicate` for the C#
  extension. Losing it does not error; roslyn just stops building.
- **Text inside a `''` block is Lua, not Nix**, and ships into `init.lua`. An
  interpolation at column 0 reindents the block; a `${` meant for Lua must be
  `''${` (`.claude/rules/lua-in-nix.md`).
- **`git add -A` before every `nix` command** (flakes see only tracked files) and
  **never `nix flake update`** (it moves pins). Hooks enforce both.

Do not claim a build works without having built it.

```bash
./scripts/verify.sh build        # all three outputs — the real check
nix flake check                  # cheap eval sweep
./scripts/verify.sh <ref>        # structural: prove nothing changed but order
```

`verify.sh` compares **store paths**: identical paths are a proof, an eyeball
diff is not.

## 8. Known divergences

**A ratchet, not a ledger:** if a task touches a file listed here, migrate it in
the same change or state why not. Closed items are deleted; survivors keep their
numbers. **Nothing is currently divergent** — the tree matches §1–§7; give the
next one number 12. The absent `checks`/`formatter`/`devShells` output is
deliberate rather than an item (`.claude/rules/settled-decisions.md`,
*Deliberately deferred*).

## 9. Anti-patterns

| Anti-pattern | Why |
| --- | --- |
| `core/`, `gui/`, `min/` directories | Paths encode the variant (Inv. 4) |
| `lib/` directory of helpers | Not a flake-parts module (Inv. 1) |
| `default.nix` listing siblings, or any `imports = [ ./foo.nix ]` under `modules/` | `import-tree` already loaded them (Inv. 5) — a hook rejects it |
| `_` to group related `.nix` modules | `/_` is for non-modules only (§4) |
| A `keymaps/` directory grouping binds by domain | Splits a plugin from its own bind — settled, `d53d10b` |
| Aspect named `minimal` / `extras` / `ide` | Magnitude or archetype, not a decision (§3) |
| A third aspect no variant declines | Structure without a decision (§3) |
| `mkEnableOption` per aspect | Variants compose by taking aspects, not by enabling |
| One file branching on which variant loaded it | Aspects are variant-agnostic (Inv. 6) |
| Editing two files to add one language | Wrongly decomposed (Inv. 3) — but one file declaring two aspects is not this |
| Plain `false` in `core` where `gui` must override | Needs `lib.mkDefault` (§7) |

## 10. Working style

- **There is a skill for each recurring job:** **add-language**,
  **add-plugin-or-feature**, **add-variant**, **structural-change-checklist**.
  Run the checklist before committing any structural change — moving or
  regrouping files, touching aspects, a variant's list, or the generator.
- **Auditing aspect membership?** The **aspect-auditor** agent does it in an
  isolated context, returning conclusions rather than file dumps.
- **Prefer adding a file to editing one**, especially when extending an aspect.
  Do not add an enable flag; split into two files and let variants differ by aspect.
- **Small, single-concern commits.** Rationale in the commit message — *why*,
  not *what*; the diff already shows what. One logical change per commit: if the
  subject needs the word "and", it is probably two. A change touching many files
  for one reason is still one commit, and a coherent change is never split just
  because its message would run long — a long body is fine, an incoherent
  history is not. **Never mix a reformat or a rename with a behaviour change.**
- **Commit with an explicit pathspec — `git commit -- <paths>`.** The PreToolUse
  hook and `verify.sh` both run `git add -A`, so by commit time the whole tree is
  usually staged; a pathspec commits those paths whatever the index holds. **This
  includes `--amend`** — a bare `git commit --amend` re-uses the entire index and
  silently widens the commit it is fixing. Read `git status` first and leave
  anything that is not yours unstaged. Generated files, build artefacts and
  editor config stay out unless the project expects them.
- **Branch off `main`; rebase onto it before opening a PR if it has diverged.**
  Keep the branch's commits atomic. Do not treat squash-merge as licence for
  messy intermediates — either commit cleanly and preserve history at the merge,
  or commit messily and write a good squash message. Not both.
- **A PR is reviewable in one sitting, or it is too large** — split it into
  stacked PRs or independent changes. The title follows the commit-subject
  convention; the description is one sentence of context, then dot points
  covering decisions rather than diffs. If it will be squash-merged, that
  description *is* the squash commit body.
- **`.githooks/` enforces the mechanical half** of the above; the judgement above
  is yours. `core.hooksPath` is per-clone local config, so a fresh checkout runs
  `./scripts/install-hooks.sh` once before any of it applies.
- **A `.nix` file gets one kind of comment, and only one:** a one-line
  `# load-bearing: docs/<area>.md#anchor` at a value whose change breaks
  something non-obviously. No banners, no restating the line below, no
  commented-out alternatives. Reasoning goes in `docs/`, and **changing a
  decision means changing its entry in the same commit.**
- **Text inside a `''` block is content, not a comment.** A `--` there ships into
  `init.lua` and moves a store path. Label what the block produces, never argue
  for a value, and **two lines is the cap** — a hook enforces it.
- **No unrequested changes.** No plugin bumps, no deprecation fixes, no
  reformatting files the current task doesn't touch.
- **Do not introduce a framework** (`snowfall`, `den`, `flake-file`) and do not
  swap nvf for nixvim/nixCats without being asked. `flake-parts` and
  `import-tree` only.
- **Do not run `nix flake update`** — a hook blocks it. Adding an input and
  running `nix flake lock` is fine.
- **Finished plans go to git history.** Cite a §-number or commit hash, never a
  plan filename.
- **If a request genuinely doesn't fit the pattern,** say so and give options with
  their costs. Do not silently bend an invariant.
