# decisions/formatters

## PATH resolution

**Why:** `modules/formatter.nix` sets **every** `formatters.<name>.command` to a
bare name with `lib.mkForce`, so conform resolves each from `$PATH` at runtime
instead of taking nvf's pinned store path. The `mkForce` is required — nvf sets
them at normal priority, so a plain assignment conflicts rather than overriding.
csharpier's is `mkForce null`, not a name — its daemon resolves the bare name
itself (`docs/decisions/csharp.md#csharpier-formats-roslyn-is-the-fallback`).
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

## The prettier formatter runs prettierd

**Why:** prettier boots node per invocation — measured 94–116 ms on a
one-line file (2026-09-02) — paid synchronously on every
ts/tsx/css/scss/html/json/yaml/markdown save. prettierd halves that, not
more: 41–51 ms warm (measured 2026-09-02), because its client is itself a
node script — the floor is a bare node boot; what the daemon removes is
loading prettier and resolving config. The swap happens at the formatter
*definition*, not the routing: nvf types every `format.type` as
`listOf (enum …)` and no enum contains `prettierd`, so each language keeps
`format.type = ["prettier"]` (and yaml's `"yaml.gitlab"` key keeps
`["prettier"]`) while the entry named prettier execs `prettierd`. The daemon
resolves the project's own prettier from `node_modules` before its bundled
one, so a devshell's version still wins — the rule `preferPathExe` enforces
everywhere else. `args` must be forced to `["$FILENAME"]`: prettierd takes
the path as its only argument with the buffer on stdin, and rejects the
preset's `--stdin-filepath`. The `dev` fallback pins `pkgs.prettierd` in
prettier's `preferPathExe` slot — 290.4 MiB against prettier's 261.5 MiB
(measured 2026-09-02), both dominated by node.

nvf itself *removed* prettierd (rl-0.8: "high complexity that would be
needed to support it"; dropped from the last modules in rl-26.07) — but that
complexity is plugin injection: nvf pins prettier plus store-path plugins
for astro/svelte and cannot feed those into a daemon. This repo pins
nothing; prettierd takes prettier and its plugins from the project, so the
refused complexity never arises. Do not re-align with nvf on this.

**Breaks:** silently, in the one direction that looks like a cleanup:
"fixing" `command` back to `prettier` while the forced `args` stand hands
prettier a bare filename, and prettier then ignores stdin and formats the
*on-disk* file — stale content wins over the unsaved buffer with no error
anywhere. Dropping the `args` force instead fails loudly (`--stdin-filepath`
reaches prettierd, `conform.log` shows the rejection). prettierd's per-project
daemons also linger after the editor exits (core_d's design) — `prettierd
stop` reclaims them. Without prettierd on `$PATH` the standard degradation
applies: conform skips the formatter and the save goes through unformatted.




## format-on-save gates on a global

**Why:** conform's `format_on_save` returns nothing when
`vim.g.disable_autoformat` is set — `<leader>tf` (also in
`modules/formatter.nix` — the file that installs a feature owns its keymap)
flips that global — and otherwise formats every filetype synchronously on
save. cs gets `timeout_ms = 3000` instead of conform's 1000 default, sitting
above the csharpier daemon's internal 2.5 s wait-for-boot deadline
(`docs/decisions/csharp.md#csharpier-formats-roslyn-is-the-fallback`), so the
one save that can land before the server binds still formats instead of
timing out. `format_after_save = null` retires the async half entirely — cs
formatted there until 2026-09-01, when the daemon removed the per-invocation
dotnet boot that justified the split (`f9959b5`). nvf has its own toggle
machinery (`vim.g.formatsave`, buffer-local `<leader>ltf`), but all of it sits
under `mkIf vim.lsp.enable`, so `min` never gets it — the gate has to live at
the conform layer to exist in every build, and it deliberately ignores nvf's
globals rather than half-reading them.

**Breaks:** silently, in two ways. Replacing `format_on_save` with a plain
`{}` (the pre-toggle value) formats on every save again and the keymap keeps
announcing states it no longer controls. And `format_after_save` must stay a
defined `null`, never deleted: dropping the definition resurrects nvf's
default for it, which is gated on `vim.g.formatsave` — every save in a `dev`
build then formats twice, sync and async, which is what this gate replaced.
