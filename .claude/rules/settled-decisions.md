---
paths: "flake.nix,modules/variants/**,modules/aspects.nix,REFACTOR.md,README.md"
---

# Settled decisions — do not re-propose

These shapes were argued to a conclusion. Changing one is a new decision the
human makes, not a cleanup you offer. Rationale lives in git history — cite a
commit hash, never a plan filename.

- **nvf is the framework.** Not nixvim, not nixCats, not a hand-rolled `mnw`
  wrapper. A migration is a rewrite of every file in the repo and is not on the
  table as a side effect of the dendritic refactor.
- **flake-parts and import-tree only.** No `snowfall`, `den`, `flake-file`,
  `easy-hosts`, or any other framework, unless asked.
- **`default`, `min` and `gui` are the output names**, and `default` aliases
  `min`. `~/.dotfiles/flake` reads two of them by name. Adding a variant is fine;
  renaming one is a breaking change to another repo.
- **Two aspects: `core` and `gui`.** An aspect earns its existence when some
  variant declines it, and there are two variants. Do not pre-split `gui` into
  `lsp`/`ui`/`db`/`neovide` — that is structure without a decision behind it.
  When a third variant appears, split at the seam *that variant* declines.
- **Home Manager consumption stays out of this repo.** It exports packages, not a
  `homeModules.default`. The consumer wires it (`flake/modules/neovim.nix`,
  `flake/modules/neovide.nix`); `home-example.nix` documents the shape for
  anyone else.
- **`core` resolves rustfmt and clang-format from `$PATH`, deliberately**
  (`modules/formatter.nix`), so both builds do. Pinning them in `min` is a
  ~4.5 GB closure regression. Not an oversight, not a `mkForce` to clean up.
- **`preferPath` prefers the `$PATH` binary over the pinned one, deliberately.**
  It exists so a project's own toolchain wins inside a devshell. Its silent
  fallback is a known cost, not a bug to fix.
- **The file that installs a feature owns its keymap.** Not a `modules/keymaps/`
  directory grouped by domain — that shape was deleted in Stage 4, and
  `modules/database.nix` is the exemplar. A bind with no installing file is its
  own concern and gets its own file (`modules/movement.nix`,
  `modules/search.nix`). Re-grouping binds by mechanism is a re-litigation, not a
  cleanup.
- **`preferPathExe` is a flake-parts option** (`modules/prefer-path.nix`),
  declared `functionTo raw` and taking `pkgs` explicitly, because the top-level
  flake-parts `config` is not per-system. A language file reaches it by capturing
  the flake-parts `config` in an outer `let`. Chosen over a `/_` expression so no
  language file carries a relative import path. Weak typing is the accepted cost.

## Deliberately deferred — do not propose unasked

- A `checks` output, a `formatter` output, or a `devShells` output. CLAUDE.md §8
  item 11 records the gap; nothing schedules it.
- Migrating the C# stack away from roslyn, or dropping the
  `allowUnfreePredicate` that makes it build.
