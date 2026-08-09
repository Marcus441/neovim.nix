# decisions/formatters

## PATH resolution

**Why:** `modules/formatter.nix` sets `rustfmt.command` and
`clang-format.command` to bare names with `lib.mkForce`, so conform resolves
them from `$PATH` at runtime instead of taking nvf's pinned store paths. The
`mkForce` is required — nvf sets both at normal priority, so a plain assignment
conflicts rather than overriding.

**Breaks:** silently, and in the direction that matters. Pinning either one
drags its whole toolchain into `core`, which means into `min`, which ships to
every host: roughly 2.4 GB for rust and 2.1 GB for LLVM. The build still
succeeds. Nothing warns. Check the closure size, not just that it built —
`min` is about 0.53 GB and `gui` about 3.57 GB.

**Also:** this is the counter-pressure that earns the `gui` aspect at all
(CLAUDE.md §6). The trade is deliberate: a host without rustfmt on `$PATH` gets
no rust formatting, and that is preferred to a 2 GB regression on every host.
Settled — see `.claude/rules/settled-decisions.md`.
