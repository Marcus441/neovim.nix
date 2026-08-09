# CLAUDE.md — nvf configuration, going dendritic

This repository is being refactored to **the dendritic pattern** — an
aspect-oriented approach where every Nix file is a flake-parts module organized
by feature, not by which build it belongs to. If a change would violate an
invariant, stop and say so — the invariants are the whole value of this
structure, and a single exception metastasises.

**Stages 0–2 have landed.** flake-parts, import-tree, the aspect options and the
variant generator are in place, the profile directories are gone, and
`modules/languages/<lang>.nix` is one file per language. What remains is
`modules/options.nix`, which is still a grab-bag, and the two keymap shapes. §1
describes the target; §8 describes the tree as it actually is. `REFACTOR.md` is
the live plan. Read §8 before treating a file as an example to copy.

| Output | Aspects | Consumed by |
| --- | --- | --- |
| `min` | `core` | `home.packages` on every host |
| `default` | `core` | alias of `min` |
| `gui` | `core` `gui` | `programs.neovide.settings.neovim-bin` |

Two distinct derivations, three output names. **The three names are public API** —
`~/.dotfiles/flake` pins `github:Marcus441/neovim.nix` and reads
`packages.${system}.min` and `.gui`. Renaming one breaks the desktop.

**Local edits do not reach the machine.** The consuming flake pins a GitHub
revision, not this working tree. Nothing here takes effect until it is pushed and
that input is updated — which the human does, not you.

## 1. Invariants

1. **Every `.nix` file under `modules/` is a flake-parts module.** One
   interpretation, always. Not an nvf module, not a package expression, not a
   helper library.
2. **`flake.nix` is a manifest.** Inputs + `mkFlake` + `import-tree`. No
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
**merge**. The merge runs both ways: **many files → one aspect** (grow a feature
by adding a file, never editing a list) and **one file → many aspects** (the
direction that gets forgotten). The unit of **concern** is the *file*; the unit
of **applicability** is the *aspect*. Neither contains the other.

There is **one class** here (`nvf`), where the sibling flake has three. That
removes the cross-class pressure that keeps files honest there, so the discipline
has to come from aspects alone: a file that touches both builds is one file, not
two.

## 3. Aspects

An aspect is a **decision or a capability**, never a magnitude and never a build
name.

**An aspect earns its existence when some variant says no.** With two variants,
exactly one declining aspect is earned, and it is `gui`. Everything else is
`core`. Files still decompose freely by concern — `modules/languages/rust.nix`
declares both memberships — but a third aspect needs a third variant to decline
it, or it is structure without a decision behind it.

- Good, when earned: `gui`, `db`, `neovide`.
- Bad: `minimal`, `extras`, `heavy` — magnitude names rot.
- Bad: `terminal`, `ide` — a build archetype. The archetype is the *list*.

When a third variant appears, split `gui` at the seam that variant declines and
put the new names where `gui` sat (§5). Until then, do not pre-split.

## 4. Layout — the target

Descriptive, not normative. `import-tree` does not care where any file lives.

```
flake.nix                    # inputs + mkFlake + import-tree. Rarely touched.
modules/
  aspects.nix                # declares flake.modules and aspectRequires options
  variants/generator.nix     # the ONE permitted central wiring point
  variants/<name>.nix        # what a build IS: an aspect list
  <concern>.nix              # declares its own aspect membership
  languages/<lang>.nix       # one language, every aspect it touches
  <intent>/                  # implementations of one intent, in different aspects
  **/_*                      # .nix files that are NOT modules — import-tree skips them
```

**Prohibited:** `core/`, `gui/`, `min/` (encode the variant — Inv. 4 inverted);
`lib/` (not a flake-parts module — Inv. 1); a barrel `default.nix` whose only
content is `imports` (Inv. 5).

**Permitted:** anything whose name does not predict the aspect of every file
inside. `languages/` is fine; a `gui/` holding only `gui` files is not.

`import-tree` imports **`.nix` files only** — a `.lua`, `.json` or `.md` asset
sits at any ordinary path and is read with `builtins.readFile`. `/_` is for
`.nix` files that are not modules: expressions consumed by `import`, derivations
consumed by `callPackage`, dormant code. **It is not a grouping mechanism.**

## 5. Ordering and store paths

Order is the one thing about this structure that reaches a derivation hash, and
here it is more exposed than in a NixOS config: **nvf's list options concatenate
in module order**, and that order becomes the order of the generated `init.lua`.

- `vim.augroups`, `vim.autocmds`, `vim.keymaps`, `vim.treesitter.queries` are
  **lists**. Merging two files into one, or renaming a file so it sorts
  differently, reorders them.
- **A plugin's `setupOpts` lists concatenate too**, and they concatenate against
  *nvf's own defaults*, not just against your files — `blink-cmp`'s
  `sources.default` holds ours and nvf's back to back today. Where a key is
  defined twice, module order picks which definition wins at runtime: Stage 0
  flipped `blink-cmp`'s `keymap."<C-d>"` that way (`2ea202f`).
- `vim.extraPlugins` is an attrset keyed by name — order comes from `after`, not
  from file order.
- **Import order** is a depth-first walk, per-directory alphabetical.
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

**Default to `core`. Justify the exception.** `min` is the editor that ships to
every host; `gui` is one program's launcher. A line in `gui` that could have been
`core` is a line the terminal editor does without for no reason.

The counter-pressure is closure size — `core` deliberately resolves rustfmt and
clang-format from `$PATH` rather than pinning them
(`modules/formatter.nix`), because each pins a ~2 GB toolchain. **A `core`
line that drags a toolchain into `min` is the exception that justifies `gui`.**

## 7. Hazards and verification

- **Every *file* is evaluated once** — a syntax error anywhere breaks both
  builds. But an **aspect's contents are only evaluated by variants that take it.**
- **`core` sets `lib.mkDefault false`; `gui` overrides it.** That is this repo's
  central mechanic and its sharpest edge: `lib.mkDefault` in `core` and a plain
  value in `gui` is the *only* combination that works. Detail and the rest of the
  override table: `.claude/rules/evaluation-hazards.md`.
- **`config` shadowing** inside `flake.modules.*` — that `config` is nvf's, not
  flake-parts'.
- **`pkgs` here is not stock.** It carries an `allowUnfreePredicate` for the C#
  extension. Losing it does not error; roslyn just stops building.
- **Text inside a `''` block is Lua, not Nix.** It ships into `init.lua`. An
  interpolation at column 0 reindents the block; a `${` meant for Lua must be
  `''${`. See `.claude/rules/lua-in-nix.md`.
- **`git add -A` before every `nix` command** (flakes see only tracked files) and
  **never `nix flake update`** (it moves pins). Hooks enforce both.

Do not claim a build works without having built it.

```bash
./scripts/verify.sh build        # all three outputs — the real check
nix flake check                  # cheap eval sweep
./scripts/verify.sh <ref>        # structural: prove nothing changed but order
```

`verify.sh` proves equivalence by comparing **store paths**. Identical paths are
a proof; an eyeball diff is not.

## 8. Known divergences

**This is a ratchet, not a ledger:** if a task touches a file listed here,
migrate it in the same change, or state why not. Item numbers are stable
identities — closed items are deleted and survivors keep their numbers.

Nothing left here is structural — every remaining item is a file that holds too
much or a shape that exists twice. `REFACTOR.md` is the plan; the stage that
closes each item is named.

7. **`modules/options.nix` is a grab-bag** — `vim.options` mixed with about
   sixteen plugin enables across its two aspects (Inv. 3). *Stage 3.*
8. **Keymaps are inconsistently placed.** Undotree's bind is in
   `modules/keymaps/general.nix` while the plugin is in
   `modules/extra-plugins.nix`; dadbod's bind is inline in
   `modules/database.nix`. One shape, not two. *Stage 4.*
9. **`modules/options.nix` writes `config.vim`; every other file writes bare
   `vim`.** Both are valid; the inconsistency is not. *Stage 3.*
10. **`.luarc.json` and `.luacheckrc` reference a `lua/` layout that no longer
    exists.** Confirm dead, then delete. *Stage 5.*
11. **No `checks`, no `formatter`, no `devShells` output.** `nix flake check` is
    currently near-empty. Not scheduled; raise it if a stage needs it.

## 9. Anti-patterns

| Anti-pattern | Why |
| --- | --- |
| `core/`, `gui/`, `min/` directories | Paths encode the variant (Inv. 4) |
| `lib/` directory of helpers | Not a flake-parts module (Inv. 1) |
| `default.nix` that only lists siblings | `import-tree` already loaded them (Inv. 5) |
| `imports = [ ./foo.nix ]` inside `modules/` | Same (Inv. 5) — a hook rejects it |
| `_` to group related `.nix` modules | `/_` is for non-modules only (§4) |
| Aspect named `minimal` / `extras` / `ide` | Magnitude or archetype, not a decision (§3) |
| A third aspect no variant declines | Structure without a decision (§3) |
| `mkEnableOption` per aspect | Variants compose by taking aspects, not by enabling |
| One file branching on which variant loaded it | Aspects are variant-agnostic (Inv. 6) |
| Editing two files to add one language | Wrongly decomposed (Inv. 3) — but one file declaring two aspects is not this |
| Plain `false` in `core` where `gui` must override | Needs `lib.mkDefault` (§7) |

## 10. Working style

- **There is a skill for each recurring job.** **add-language**,
  **add-plugin-or-feature**, **add-variant**, and
  **structural-change-checklist**. Use the checklist before committing any
  structural change — moving/renaming/regrouping files, adding/splitting/renaming
  aspects, changing a variant's aspect list, editing the generator or
  `aspects.nix`, or executing a `REFACTOR.md` stage.
- **Auditing aspect membership?** The **aspect-auditor** agent does it in an
  isolated context and returns conclusions rather than file dumps.
- **Prefer adding a file to editing one**, especially when extending an aspect.
  Do not add an enable flag; split into two files and let variants differ by aspect.
- **Small, single-concern commits.** Rationale in the commit message.
- **A `.nix` file gets one kind of comment, and only one.** A one-line
  `# load-bearing: docs/decisions/<area>.md#anchor`, at a value whose change
  breaks something non-obviously. Nothing else: no section banners, no restating
  the line below, no commented-out alternatives. The reasoning goes in `docs/` —
  `conventions/` for what recurs across files, `decisions/` for why one file made
  its call — and **changing a decision means changing its entry in the same
  commit**. A register that drifts is worse than none.
- **Text inside a `''` block is content, not a comment.** A `--` there ships into
  the generated `init.lua`, so adding or removing one moves a store path. **Label
  what the block produces; never argue for a value.** **Two lines is the cap:**
  needing a third means it is an argument, and arguments belong in `docs/`. A
  PostToolUse hook enforces the cap.
- **No unrequested changes.** No plugin bumps, no deprecation fixes, no
  reformatting files the current task doesn't touch.
- **Do not introduce a framework** (`snowfall`, `den`, `flake-file`) and do not
  swap nvf for nixvim/nixCats without being asked. `flake-parts` and `import-tree`
  only.
- **Do not run `nix flake update`.** Adding an input and running `nix flake lock`
  is fine. A hook blocks the bare update.
- **Finished plans go to git history.** Cite a §-number or commit hash, never a
  plan filename. `REFACTOR.md` is deleted when its last stage lands.
- **If a request genuinely doesn't fit the pattern,** say so and give options with
  their costs. Do not silently bend an invariant.
