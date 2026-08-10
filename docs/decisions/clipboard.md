# decisions/clipboard

## Providers are Linux only

**Why:** nvf's `vim.clipboard.providers` submodule offers exactly three
providers — `wl-copy`, `xclip` and `xsel` — and all three are Linux clipboard
bridges. Naming one puts its package into nvf's `extraPackages`, and
`wl-clipboard` drags in `wayland`, which nixpkgs refuses to evaluate on darwin.
So the attrset is wrapped in
`lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux` and darwin takes none.

Nothing needs to replace them there. macOS Neovim finds `pbcopy`/`pbpaste` by
itself, so `enable` and `registers = "unnamedplus"` stay unconditional and `"+`
reaches the system clipboard on every platform — there is no darwin provider to
add, and adding a package would be the wrong fix.

**Breaks:** loudly, at eval, and for *every* output rather than just the
clipboard. Without the guard `packages.<darwin>.min`, `.default` and `.gui` all
fail with `Refusing to evaluate package 'wayland-…' … not available on the
requested hostPlatform`, several frames inside `wl-clipboard`'s `buildInputs`,
naming nothing in this repo. Measured 2026-08-10: that is exactly what all four
darwin outputs did beforehand, and it is why the kotlin-lsp darwin work could
only be verified by neutralising this file first.

**Also:** the guard excludes by *attribute*, not by value — `lib.optionalAttrs`
rather than `enable = false` — per `.claude/rules/evaluation-hazards.md`,
because the excluded branch names packages that cannot exist on the host and
only dropping the attribute leaves them unreferenced.

It is a **platform** test, not a variant test, so Inv. 6 holds: aspects stay
variant-agnostic and the system axis is already `packages.<system>.<variant>`.
A `darwin-core` aspect could not express this even if it were wanted —
`variants.<name>.aspects` is a static `listOf str` evaluated outside
`perSystem`, so no variant can decline an aspect per system, and nothing would
decline it anyway (CLAUDE.md §3). Platform belongs in `pkgs`, alongside the
`isDarwin` and `dists ? ${system}` tests in `modules/languages/kotlin.nix`.
