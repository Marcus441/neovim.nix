---
paths: "modules/variants/**,modules/aspects.nix,flake.nix"
---

# Variant wiring

`modules/variants/generator.nix` is **the ONE permitted central wiring point** —
the only place a manual module list is allowed (Inv. 5). `modules/aspects.nix`
declares the `flake.modules` and `aspectRequires` options.
`modules/variants/<name>.nix` says what a build *is*: an aspect list, and nothing
else.

```nix
# modules/variants/gui.nix
{
  variants.gui.aspects = [ "core" "gui" ];
}
```

The generator turns each variant into `perSystem.packages.<name>`:

```nix
packages.${name} = (inputs.nvf.lib.neovimConfiguration {
  inherit pkgs;
  modules = map (a: config.flake.modules.nvf.${a}) variant.aspects;
}).neovim;
```

## The output names are public API

`~/.dotfiles/flake/flake.nix:11` pins `github:Marcus441/neovim.nix`;
`flake/modules/neovim.nix` reads `packages.${system}.min` and
`flake/modules/neovide.nix` reads `.gui`. `default` must stay an alias of `min`.

**Adding** a variant is an API addition and is cheap. **Renaming or removing**
one breaks the desktop at the next `nix flake update` on that side, with an error
that names this flake and not the reason.

**Local edits do not reach the machine.** The consumer pins a revision, not this
path. Nothing takes effect until pushed and the input updated — the human's call.

## What the generator should reject

- an aspect name that resolves in no aspect (a typo silently contributes nothing
  otherwise — `flake.modules` is an open attrset);
- an unmet `aspectRequires`;
- a variant whose attribute name disagrees with its record.

**When an aspect depends on another, declare `aspectRequires` in the file that
creates the dependency** — a central table would not know when a file stops
reading. It is the check that turns "this build came out subtly wrong" into "this
variant is missing an aspect".

## Aspect order is load-bearing

A variant's aspect list is the module order handed to nvf, which is the order
`vim.augroups`, `vim.autocmds`, `vim.keymaps` and `vim.treesitter.queries`
concatenate in, which is the order they appear in the generated `init.lua`, which
reaches the store path. When splitting an aspect, put the new names where the old
one sat. Measure with `scripts/verify.sh`; do not predict.

## `pkgs` is not stock

`flake.nix:16-22` instantiates nixpkgs with an `allowUnfreePredicate` for
`vscode-extension-ms-dotnettools-csharp`. Under flake-parts this must be
re-established, or the C# extension stops building — and it fails as an unfree
refusal at a distance, not at the line that lost the predicate:

```nix
perSystem = { system, ... }: {
  _module.args.pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = p: builtins.elem (lib.getName p) [ … ];
  };
};
```

## `systems`

`flake-utils.lib.eachDefaultSystem` currently enumerates the default systems.
flake-parts wants an explicit `systems` list. Keeping the same set keeps the
`eachDefaultSystem` behaviour; narrowing it to `x86_64-linux` is a deliberate
API narrowing, not a cleanup — the consumer indexes `packages.${system}`.
