# decisions/kotlin-lsp

## The server is vendored

**Why:** nixpkgs has no `kotlin-lsp` — `nixos-unstable` carries only
`kotlin-language-server`, the fwcd server this repo already tried and removed.
JetBrains publishes kotlin-lsp only as a per-platform archive on its own CDN, so
`modules/languages/kotlin.nix` fetches that archive and patches it. The version
and all four per-system hashes sit in the `dists` attrset at the top of the
file; bumping the server is editing that one record.

The archive is not on GitHub. Releases are tagged `kotlin-lsp/vNNN.NNNN.N` in
`Kotlin/kotlin-lsp` with **no** release assets — the body links to
`download-cdn.jetbrains.com/language-server/kotlin-server/<version>/`, and
`kotlin-server-<version>.tar.gz` is x86_64 while `-aarch64.tar.gz` is arm64
(`.sit` is the same pair for macOS, `.win.zip` is Windows). JetBrains publishes
a `.sha256` beside each, so a bump needs no 376 MB download: `curl` the
checksum and run `nix hash convert --to sri --hash-algo sha256 <hex>`.

All four systems in `modules/systems.nix` are wired up: two Linux tarballs and
the two macOS `.sit`s, `-aarch64.sit` for Apple silicon and the unsuffixed
`.sit` for Intel. Note that nixpkgs 26.05 is the last release to support
`x86_64-darwin`, so that entry has a known expiry.

**Breaks:** at eval, loudly, on any platform outside `dists` — no such platform
is currently in `modules/systems.nix`, so the guard is dormant rather than
load-bearing. It is an `if dists ? ${system}` around a lazy `let`, not a
`mkIf` — see `.claude/rules/evaluation-hazards.md` on excluding by attribute
rather than by value, because the excluded branch names a derivation that
cannot be built there. The fallback that guard selects is the bare string
`kotlin-lsp`, i.e. whatever is on `$PATH`, if anything.

**Also:** the entrypoint is **`bin/intellij-server`**, a native ELF launcher, not
a jar and not a shell script. `kotlin-lsp.sh` still exists at the archive root
but only prints a deprecation warning and execs `bin/intellij-server "$@"`, so
the install wraps the real launcher and skips the shim. There is no `kotlin-ls`
binary anywhere in the distribution: upstream's `scripts/neovim.md` invents that
name for a symlink the reader is told to create by hand, which is why every
copied-around Neovim snippet says `cmd = { "kotlin-ls", "--stdio" }`. The
wrapper here is named `kotlin-lsp`, matching the README's own "Install
kotlin-lsp CLI" and the Homebrew formula.

## The darwin archive is a zip

**Why:** JetBrains names the macOS build `.sit`, but it is not StuffIt — the
bytes are an ordinary zip (`PK\x03\x04`, a normal end-of-central-directory, 912
entries under a single `kotlin-server-<version>/` root). stdenv's `unpackFile`
dispatches on the *extension* of the store path, and no hook matches `.sit`, so
the unmodified fetch dies with `do not know how to unpack source archive`. The
fix is one line: `fetchurl` takes an explicit `name` ending in `.zip`, which is
what `unzip`'s `_tryUnzip` hook matches on, and `unzip` joins
`nativeBuildInputs`. Renaming the *store path* is all it takes; the URL keeps
its `.sit`.

The extracted tree is byte-for-byte the shape the Linux tarball has —
`bin/intellij-server` (Mach-O, and marked `100755` in the zip's Unix external
attributes, so it lands executable), `jbr/` holding the macOS
`Contents/Home` bundle, and 221 symlinks that `unzip` restores. So the
`installPhase` is shared with Linux unchanged.

**Also:** the ELF apparatus is Linux-only and is now guarded as such —
`autoPatchelfHook`, the `stdenv.cc.cc.lib`/`zlib` `buildInputs` and the
`autoPatchelfIgnoreMissingDeps` soname list all sit behind
`lib.optionals (!isDarwin)`. On Mach-O `autoPatchelfHook` is not an error, it
is a silent no-op — `auto_patchelf_file` catches `ELFError` and returns nothing
— so the guard buys correctness and a smaller darwin build closure, not a fixed
build. The guards are written so the Linux lists are unchanged: verified by
store path, `kotlin-lsp-262.9593.0` is identical before and after.

**Breaks:** loudly at build time, on darwin only, if JetBrains ever switches
the `.sit` to a real StuffIt container — the symptom is `unzip` failing on a
bad signature rather than the old "do not know how to unpack". Check the magic
with `curl -r 0-3` before assuming a hash bump is enough.

## The bundled runtime is headless

**Why:** the archive ships its own JetBrains Runtime (`jbr/`, Java 25) and the
launcher resolves it relative to itself, so the package keeps the tree intact
under `$out/libexec/kotlin-lsp` and `makeWrapper`s the launcher into `$out/bin`.
A symlink would not do — the launcher finds `IDE_HOME` from its own location.
On Linux `autoPatchelfHook` fixes the interpreter and the JBR's shared objects;
darwin needs no equivalent, because the Mach-O binaries resolve their libraries
inside the preserved tree and against the system's own dyld cache.

Ten of those shared objects want a GUI or an audio stack that a language server
never loads: AWT under X11 and Wayland, `libsplashscreen`, `libfontmanager`,
`libjsound`. They are listed in `autoPatchelfIgnoreMissingDeps` rather than
satisfied, because satisfying them means dragging X11, Wayland, freetype and
ALSA into the closure of an editor that talks JSON-RPC over a pipe.

**Breaks:** loudly at build time if a future release needs a library that is
*not* on that list, which is the point of listing sonames instead of setting the
flag to `true`. A genuinely-needed library would instead surface at runtime as
an `UnsatisfiedLinkError` in the server log; a clean `initialize` handshake
against a Gradle project logs no exception at all, and that is the check.

**Also:** this costs **1.2 GiB** in `gui`'s closure — 4.2 GiB to 5.4 GiB — and
nothing in `min`, which stays at 315 MiB. It is the single largest thing `gui`
pulls in, ahead of roslyn. That is the price of an IntelliJ-derived server and
the reason it is a `dev` line and could never be a `core` one (AGENTS.md §6).

## It is unfree

**Why:** the `Kotlin/kotlin-lsp` repository is Apache-2.0, but the repository is
not what gets fetched. The published server "is based on the most recent
IntelliJ IDEA version and proprietary parts of JetBrains Air and Fleet products,
making it partially closed-source" (upstream README), and the archive carries no
top-level licence beyond third-party notices. `meta.license` is therefore
`lib.licenses.unfree`, and `kotlin-lsp` is named in the `allowUnfreePredicate`
allowlist in `modules/nixpkgs.nix` alongside the C# extension.

**Breaks:** loudly, at eval, with an unfree refusal pointing at `gui` — the same
failure mode `docs/decisions/nixpkgs.md` describes for roslyn. Dropping the
allowlist entry does not disable Kotlin; it stops `gui` evaluating at all.

## The built-in module keeps everything except the server

**Why:** `vim.languages.kotlin.enable` is on for treesitter and for ktlint
diagnostics; only `lsp.enable` is off. nvf's kotlin module hard-codes
`servers = ["kotlin-language-server"]` as the sole member of an `enum`, so no
option value selects the JetBrains server. The module is kept for what it does
offer, and the server is declared beside it at `vim.lsp.servers`, which is
freeform and which nvf enables on its own — `vim.lsp.enable` gates
`vim.languages.*`, not entries written there directly.

**Breaks:** loudly, and that is the point. `lsp.enable` is a plain `false` here,
not the `lib.mkDefault false` every other language file in `modules/languages/`
writes, because no aspect is meant to override it — a later `lsp.enable = true`
in `dev` is a definition conflict rather than a silently resurrected fwcd
server. See `.claude/rules/evaluation-hazards.md` for why a `mkDefault` nothing
overrides is noise.

**Also:** `workspace_required = true` is Neovim's native spelling of the
`single_file_support = false` that upstream's docs ask for; the latter is an
nvim-lspconfig framework field and means nothing to `vim.lsp.config`. The
`root_markers` list puts `settings.gradle{,.kts}` ahead of `build.gradle{,.kts}`
so a multi-project Gradle build roots at the tree top and not at whichever
subproject was opened first. The server name is `kotlin_lsp`, underscored, to
match the nvim-lspconfig preset, so if lspconfig is in the runtime our table
merges over its defaults instead of starting a second client.

## Kotlin has no treesitter indent query

**Why:** nvf turns on `vim.treesitter.indent`, which sets
`indentexpr=v:lua.require'nvim-treesitter'.indentexpr()` on every buffer.
nvim-treesitter ships `indents.scm` for 169 languages; Kotlin is not one of them
— its query directory holds only `folds`, `highlights`, `injections` and
`locals`. The expression therefore runs with nothing to consult and indents
almost every line wrongly. The `FileType kotlin` autocmd in
`modules/languages/kotlin.nix` puts `indentexpr` back to `GetKotlinIndent()`,
the function Neovim's own `indent/kotlin.vim` defines.

This is the same failure as C#'s (`modules/languages/csharp.nix`) with a better
remedy available: Neovim ships no Kotlin *treesitter* query but does ship a
Kotlin *Vim* indent script, so there is something to fall back **to** rather
than merely something to fall back **from**. Measured on a 42-line sample by
`gg=G` against its own correct formatting, differing lines were: treesitter 64,
`smartindent` 26, `GetKotlinIndent()` 10. Both other options were tried before
this one was chosen.

**Breaks:** partially, and in one known place. The residual 10 lines are all
method-chain continuations — `GetKotlinIndent()` has no notion of a continuation
line, so `.filter { … }` under `return xs` lands at the parent's indent instead
of one level in. Everything else in the sample (class bodies, `when` arms, `->`
lambda bodies, multi-line parameter lists, if/else) comes out correct. The
autocmd falls back to `smartindent` if `GetKotlinIndent` is ever absent, because
an `indentexpr` naming a missing function errors on every single line.

**Also:** the autocmd is `core`, not `dev` — `min` has treesitter indent too, so
it has the same broken indent, and the fix costs nothing. In `gui` the residual
chain-continuation case is repaired on save by the server's own formatter; see
the next section. `min` keeps the 10-line residual, having no server.

## Formatting is the server's job

**Why:** kotlin-lsp advertises `documentFormattingProvider`, and that provider is
IntelliJ's Kotlin formatter — the same one the IDE uses. Pointing conform at it
costs nothing to package and is strictly better than any standalone tool: fed
the output of `GetKotlinIndent()`, it reproduced the sample's correct formatting
exactly, chain continuations included. That is the whole reason the indent
autocmd above is allowed to stay imperfect.

The wiring is a `formatters_by_ft.kotlin` entry holding **only** string keys —
no formatter names. conform's `get_opts_from_filetype` merges `lsp_format` and
`timeout_ms` from a filetype entry into the options of a format-on-save run, and
with no formatter names to resolve, `lsp_format = "fallback"` sends the buffer
to the LSP. `"fallback"` rather than `"prefer"` so that adding a real Kotlin
formatter later takes precedence without touching this line.

**Breaks:** silently, by doing nothing, if the entry is removed or the server is
not attached — a save simply leaves the buffer unformatted. `:ConformInfo` on a
Kotlin buffer is the check; `require("conform").list_formatters_to_run(0)` should
report its second return value as `true`.

**Also:** `timeout_ms` is raised to 2000 from conform's default of 1000 because
format-on-save here is **synchronous**. A warm server answers in ~130 ms, so the
margin is for a cold one that is still indexing; on timeout the save proceeds
unformatted. This is not the failure the fwcd attempt hit — `5742cac` had to
disable blocking formatting because ktlint paid JVM startup on *every* save as a
separate process, whereas this is one request to an already-running server.

## Completion may double-insert

**Why:** kotlin-lsp returns completion items with an empty `textEdit` and applies
the real edit through a follow-up command. blink-cmp inserts the label *and* the
command's edit, so an accepted completion can land twice. This config does not
work around it. `kotlin.nvim` exists for exactly this, but it takes over LSP
startup — the `vim.lsp.servers.kotlin_lsp` entry would have to go, and with it
nvf's capabilities and on-attach wiring — and it is not in nixpkgs either, so it
would arrive as a hand-pinned `fetchFromGitHub` rev.

**Breaks:** visibly, in the buffer, and only on completion accept. If it turns
out to bite in practice, revisit; the alternative is a vendored plugin whose rev
is maintained by hand against an Alpha server.

## The index cache is persistent

**Why:** the daemon (next section) is started with
`--system-path "$XDG_CACHE_HOME/kotlin-lsp"` (falling back to `~/.cache`).
Without it, kotlin-lsp picks a fresh `/tmp/idea-system<random>` every launch
and its IntelliJ engine re-indexes the whole project from zero — measured on an
Android project (2026-08-10), the server was still unindexed and had not
answered `initialize` after 280 s, on both the current build and `fd6b8c0`, so
"kotlin worked before" was a warm-cache memory, not a regression. Until
`initialize` completes, Neovim's `get_clients` hides the client and everything
reports "no active LSP" — that is a server still booting, not a failure to
attach. The flag is added *outside* `preferPathExe`, so it applies to a
devshell's kotlin-lsp too.

**Also:** the cache is **single-holder**. An IntelliJ system directory does not
tolerate two processes: measured 2026-08-10, with one editor's kotlin-lsp
attached and healthy, a second instance on the same cache sat uninitialized for
9+ minutes with no error at all — silent serialization, which reads as "one
editor blocks the other". That is why exactly one process may ever hold the
cache, and why that process is a shared daemon rather than a per-editor server.

**Breaks:** slowly and confusingly if the cache turns stale or corrupt after a
kotlin-lsp upgrade — the symptom is an Alpha server behaving oddly on a project
that used to work. Kill the daemon (`kill $(cat ~/.cache/kotlin-lsp/daemon.pid)`),
then `rm -rf ~/.cache/kotlin-lsp`; the next start pays one full re-index. The
first start on any machine still pays it too — the flag makes the second start
fast, nothing makes the first one fast.

## One daemon serves every editor

**Why:** per-editor `--stdio` servers cannot share the single-holder cache
above; the earlier flock arrangement (`94a72b6`) gave the first editor the
cache and every concurrent one a throwaway temp dir — cold at best, and for
the same project not even that (see the limitation below). The shape JetBrains
built is one long-lived server owning the cache and editors connecting to it:
`kotlin-lsp-daemon` (in `modules/languages/kotlin.nix`) starts
`kotlin-lsp --multi-client --socket 127.0.0.1:<port> --system-path $cache`
exactly once, and each editor's `cmd` is a Lua function that runs the ensure
script, reads the port off its stdout, and returns
`vim.lsp.rpc.connect("127.0.0.1", port)` — Neovim's own TCP client is the
stdio-to-socket bridge.

**The bridge is *not* `kotlin-lsp --client`.** Measured 2026-08-10 against the
pinned 262.9593.0: `--client` boots a *second* full JVM (2 GB Xmx), prints
IntelliJ logs on stdout — which alone would corrupt LSP framing — and never
answered an `initialize` sent on stdin in 60 s. It is a reverse-connection mode
for editors that listen on a socket themselves (the VSCode extension's shape),
not a thin bridge. Do not "fix" the config back to it.

**Mechanics:** the ensure script serializes on a *blocking* `flock -w 30` of
`$cache/.wrapper-lock`, held only for the check-and-start — the daemon is
spawned with fd 9 closed and `setsid -f`, so it outlives and is unhooked from
any editor. Both of those survive the move to darwin: nixpkgs' `util-linux`
builds on aarch64-darwin and its `bin/` really does carry `flock` and `setsid`,
and the `/dev/tcp` port probe is a bash builtin, which `runtimeShell` is on
both platforms; its output goes to `$cache/daemon.log`, its identity to
`$cache/daemon.pid` and `$cache/daemon.port`. A daemon counts as alive only if
its pid answers `kill -0` *and* its port accepts a connect; anything less —
including a wedged JVM that holds the pid but not the socket — is killed
(TERM, then KILL, only if `ps -p <pid> -o command=` is really
`intellij-server`) and replaced, never accreted beside, because two processes
on one system path is the hang this design exists to prevent. That identity
check reads `ps` and not `/proc/<pid>/cmdline` because macOS has no `/proc`:
there the `grep` simply never matched, so the stale-daemon branch silently
declined to kill and the script went on to spawn a *second* daemon on the same
`--system-path` — precisely the collision it exists to avoid. `ps` is pinned
from `pkgs.procps`, which supplies `bin/ps` on both Linux and darwin, so there
is one code path rather than a platform branch. Port choice: 9999 first
(kotlin-lsp's own default), then 10999/11999/12999 if a foreign listener holds
it — the winner is read from the port file at connect time, never hardcoded in
Lua. The socket accepted ~0.6 s after spawn on a warm machine, and an editor
attached through the running daemon in ~3 s; the script waits up to 30 s.

**The daemon lingers, deliberately.** `--multi-client` never self-terminates
and the binary has no idle-timeout flag, so a ~2 GB-heap JVM stays resident
after the last editor closes. Accepted: killing on last disconnect would re-pay
JVM boot and cache load every session, and an idle reaper is a
process-lifecycle job — a systemd-user unit in the machine's own config, out of
scope for a flake that only builds editor packages. Reclaim by hand with
`kill $(cat ~/.cache/kotlin-lsp/daemon.pid)`.

**What it does not fix: two editors in the same project.** Measured
2026-08-10, fresh daemon, warm index, Android project: the first editor
initialized in 3 s and held its session; a second editor on the same file
starved for its full 300 s timeout. The daemon log says why — every LSP
session opens a per-project workspace store at
`~/.config/JetBrains/analyzer/workspaces/<hash-of-project-path>/rocks/`, and
the second session dies at `RocksDB.open`: `lock hold by current process …
LOCK: No locks available`, whereupon the server drops that client and Neovim's
restart loop retries into the same wall. One session per project at a time,
*even inside one multi-client daemon*. The store is keyed by project path and
lives outside `--system-path`, so no wrapper arrangement dodges it — the
9-minute silent serialization of two stdio processes (previous section) was
this same store contending across processes instead of within one. Upstream
closed the different-*project* variant (Kotlin/kotlin-lsp#108, late 2025);
the pinned 262.9593.0 is the latest release and still has the same-project
case (cf. #141) — re-measure on the next bump. What the daemon does buy:
sequential editors re-attach in seconds instead of a JVM boot each, and
concurrent editors on *different* projects get separate workspace hashes and
one warm shared JVM (expected from the store layout; not yet measured).

**Breaks:** if the daemon dies mid-session, every attached editor's client
drops at once — Neovim reports the LSP exit, and the next client start
(`:edit` the buffer, or restart the editor) re-runs the ensure script, which
sees the dead pid and spawns a replacement — exercised, not assumed: the
staggered measurement above began with a killed daemon and the first editor's
own start respawned it. The stale pid/port files are overwritten, not trusted.
During an upgrade overlap, an old-style `--stdio` instance from a still-open
editor holds the same lock for its whole lifetime, so the new ensure script
times out after 30 s until that editor closes.
