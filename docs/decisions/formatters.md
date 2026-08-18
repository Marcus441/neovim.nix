# decisions/formatters

## PATH resolution

**Why:** `modules/formatter.nix` sets **every** `formatters.<name>.command` to a
bare name with `lib.mkForce`, so conform resolves each from `$PATH` at runtime
instead of taking nvf's pinned store path. The `mkForce` is required — nvf sets
them at normal priority, so a plain assignment conflicts rather than overriding.
`min` is meant to be opened from inside `nix develop`, so the devshell is where
its formatters come from; a pinned one is weight that is never the version the
project wants.

**Breaks:** silently, and in the direction that matters. Pinning drags each
formatter's whole toolchain into `core`, which means into `min`, which ships to
every host. The build still succeeds. Nothing warns. Check the closure size, not
just that it built — measured against `min` at 543.0 MiB, forcing each bare
saves rustfmt ~2.4 GB, clang-format ~2.1 GB, **prettier 190.5 MiB** (it drags
`nodejs`), ruff 31.5 MiB, stylua 8.9 MiB, alejandra 1.7 MiB. All of them
together took `min` from 543.0 MiB to 310.4 MiB.

**Also:** this is the counter-pressure that earns the `dev` aspect at all
(AGENTS.md §6). The trade is deliberate: a host without a formatter on `$PATH`
gets no formatting for that language, and conform skips it silently rather than
erroring. Settled — see `.claude/rules/settled-decisions.md`.

## dev re-adds a pinned fallback, core does not

**Why:** the builds that take `dev` launch with no shell and no
devshell, so the bare command `core` sets would leave it with no formatter at
all. Its half of `modules/formatter.nix` routes each one back through
`preferPathExe` — `$PATH` still wins, the pinned package is the floor. `min`
gets no such half on purpose: forcing the dev to run `nix develop` is the point.

**Breaks:** loudly at eval, in the one place worth knowing. `core` states these
with `mkForce` (50), so a `dev` `mkForce` is two definitions at the same
priority — a conflict, not an override. `dev` needs `lib.mkOverride 40`. See
`docs/conventions/overrides.md#a-formatter-command-needs-mkoverride-40`.

**Also:** `rustfmt` is deliberately absent from the `dev` half, on closure
size. It would drag the rust toolchain in and is not needed anyway — nvf
disables rust's conform formatter whenever `lsp.enable` is set, so `gui`
formats Rust through rust-analyzer. It stays bare in every build: on `$PATH` or
not at all. csharpier joined that same shape on 2026-08-18 — routed for cs but
bare in every build, a 923.9 MiB pin refused, with roslyn-ls formatting when
it is absent, see
`docs/decisions/csharp.md#csharpier-formats-roslyn-is-the-fallback`.
`clang-format` is the opposite case and free — `pkgs.clang-tools` is already
there as the clangd wrapper's fallback.



