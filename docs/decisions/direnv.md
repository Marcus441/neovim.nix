# decisions/direnv

## The stderr sink

**Why:** direnv.vim reports every export by `echom`-ing the lines it collected
on the job's stderr, and it collects them into `s:job_status.stderr` — a
script-local dict no Lua can reach. `modules/direnv.nix` redefines the plugin's
own `direnv#on_stderr` autoload function so every chunk is handed to
`_DIRENV.on_stderr` (`modules/direnv.lua`) instead. Nothing in the plugin is
patched; the redefinition is an ordinary `function!` over a global autoload
name.

A chunk is not a line. `jobstart` delivers stderr as `:h channel-lines`: the
first entry continues whatever the previous chunk ended with, the last entry is
whatever comes after the final newline, and `['']` on its own is EOF. The Lua
side keeps that trailing partial and prepends it to the next chunk, and it
treats the EOF chunk as the one reliable sign that the export is over — the
plugin's `DirenvLoaded` is not (see *The spinner*).

**Breaks:** silently, in four ways.

- **Upstream renaming `direnv#on_stderr`** leaves our definition orphaned and
  the notifications simply stop. Nothing errors — the plugin calls whatever name
  it now uses, and `_DIRENV` is never fed.
- **Redefining it any earlier than `VimEnter`.** `plugin/direnv.vim` calls
  `direnv#auto()` while start packages load, which sources
  `autoload/direnv.vim`, whose `function!` definitions overwrite ours. Package
  loading finishes before `VimEnter`, and our autocmd is registered from
  `init.lua` so it runs ahead of the plugin's own `VimEnter * DirenvExport` —
  the first export is already ours. A definition placed directly in
  `luaConfigRC` would be clobbered instead.
- **Dropping `g:direnv_silent_load = 1`.** Every message would then appear
  twice: once in fidget, once in the message log via the `echom` loop the plugin
  still runs in `direnv#on_exit`.
- **Treating a chunk boundary as a line boundary.** A `copying path` line split
  across two reads would count twice, and a `Renewed cache` split in the middle
  would match nothing. The join is what the counters stand on.

**Also:** only stderr is diverted. stdout carries the `call setenv(…)` payload
that `direnv#on_exit` feeds to `exec`, which is what actually applies the
environment; `direnv#on_stdout` is untouched for that reason. On Neovim the
plugin never resets `s:job_status` — `job_status_reset` is only called on the
Vim 8 `job_start` path — so its own stderr list grows for the life of the
session. Ours does not: `_DIRENV.start` resets the state on every export.

## Its own group

**Why:** direnv reports through a notification group it defines itself, not
through `fidget.progress.display.make_config`. Deriving it from the progress
display was the first shape and it was wrong twice over: direnv is not a
language server, and inheriting that config silently coupled it to
`modules/lsp-progress.nix` — `done_ttl`, `progress_icon`, the progress styles
and `skip_history` would all have followed edits made for LSP reasons. The
group is a plain `set_config` with its own name, spinner, `ttl` and styles, and
no `priority`, so it inherits `50` from the notification default and renders
away from the progress band at `30` rather than in the same column as
`rust-analyzer`.

**Breaks:** by rendering under the wrong group. `set_config` must have run
before *any* item is created under the key, and items are created from two
places — the deferred spinner and the `DirenvLoaded` handler — so both call
`group()` first. Registering it only in the spinner looked correct and was
not: a fast export cancels the spinner, so the result notification created the
group from `configs.default` instead, taking the default header, icon and
`ttl = 5`.

**Also breaks by not existing yet, which is why `_DIRENV` is assigned from
`luaConfigRC` and not, like the sink above, from `VimEnter`.** `DirenvLoaded`
is not fired only by an export. `plugin/direnv.vim` also registers
`autocmd BufEnter * call direnv#extra_vimrc#check()`, and `check()` calls
`direnv#post_direnv_load()` — which fires `DirenvLoaded` — whenever
`$DIRENV_DIR` is non-empty and the buffer sits under it. Launching nvim from a
shell direnv has already loaded satisfies both, out of the inherited
environment and before any export has run. The first `BufEnter` precedes
`VimEnter` at startup, so a
`VimEnter`-registered definition left the handler calling a nil global and the
error surfaced as a traceback through `direnv#extra_vimrc#check`. Assigning the
global from `luaConfigRC` is safe in a way the `direnv#on_stderr` redefinition
above is not: nothing sources a Lua global a second time, and package loading
cannot clobber it.

**Also:** the annote is the project directory and stays `Comment` in every
state — `annote_style` for an item in flight (a `nil` level falls through to
it) and `info_style` for a finished one. A directory that changed colour on
completion said nothing, and in the same grey as the message it ran into the
elapsed time, so `annote_separator` is the ` · ` the message already uses
between its own fields. State lives in the header icon instead, a `Display`
function fidget calls each render cycle: it animates while any item has no
`data`, returns `✗` if any item's `data` is `vim.log.levels.ERROR`, and `✓`
otherwise. A finished item carries its level as `data`; an item in flight
carries none. Warnings and errors keep the default `warn_style` and
`error_style`, which is what makes them the one thing that changes colour.

## The spinner

**Why:** a devenv or `use flake` `.envrc` takes seconds to evaluate cold, and
direnv.vim gives no sign it is working. A warm one does not: direnv.vim
debounces on a 500 ms timer before it even calls `jobstart`, so an unconditional
spinner would animate for ~520 ms on *every* `:cd` and carry no information
almost every time. The item is therefore opened from a `vim.defer_fn` at
`direnv_interval + 200`, and a generation counter cancels that pending open —
bumped both by a new export and by a completed one. A warm export shows the
result and never a spinner; a slow one shows the spinner and then the result in
place.

While it is open, every stderr chunk re-renders it with `update_only`, and a
one-second timer re-renders it between chunks so the elapsed time keeps moving
through a silent evaluation. `update_only` is also what keeps a fast export
from creating an item ahead of the delay: before the item exists, an update is
a no-op.

**Breaks:** by hanging a spinner on screen forever, or closing it early.

- **`DirenvLoaded` is fired by `BufEnter`, not only by an export** (the same
  path *Its own group* describes). During a 30 s devenv build every buffer
  switch fires it. The handler therefore acts only once the sink has seen the
  stderr EOF chunk and otherwise returns without touching anything. Before
  `8decf71`'s successor this was the visible bug: the first buffer switch
  resolved the item with whatever had arrived so far and cancelled the spinner.
- **No `direnv` on `$PATH`.** `direnv#export_core` echoes and returns *before*
  `jobstart`, so neither EOF nor `DirenvLoaded` ever arrives. The start handler
  checks `executable` first, mirroring the plugin's own check, and schedules
  nothing. This is why the guard is a capability check and not a timeout — it
  is the only path that bails, and it bails deterministically.
- **A stale finished item under the same key.** The open notifies with
  `ttl = math.huge` so a stale 3 s expiry cannot take the spinner down
  mid-export, but an update cannot clear `data` — fidget's `update` keeps the
  old value for `nil` and, through `x and x or y`, for `false` too — so a `✓`
  from the previous export would sit in the header for the whole run. The open
  removes the old item first. That archives it to history, where it was going
  anyway.

**Also:** an opened item that ends with nothing to say (`.envrc` that only
sleeps) closes as `loaded · 3s` rather than vanishing — the spinner promised
a result. A fast export with nothing to say creates nothing and archives
nothing: there is no item to remove, so there is no history entry to suppress.

Every handler calls `require("lz.n").trigger_load("fidget-nvim")` before
touching fidget: it is an `opt` plugin lz.n loads on `LspAttach`, and an export
normally beats any LSP attach, so a cold `require("fidget")` would fail.

## Lines, not transcripts

**Why:** the first shape concatenated every stderr line into one notification
at the end. Measured against what actually reaches the pipe, that is a wall:

| source | what it writes to a non-TTY stderr |
| --- | --- |
| direnv | `direnv: loading …`, `using flake`, `unloading`, `error … is blocked`, and after `warn_timeout` (5 s) `(…) is taking a while to execute. Use CTRL-C to give up.` The `export +A ~PATH` diff is off — `hide_env_diff = true` in `~/.config/direnv/direnv.toml`. |
| nix-direnv 3.2.0 as installed | `nix-direnv: Using cached dev shell`, `Renewed cache`, `cache invalidated: files newer than cache:` followed by bare paths. **It does not redirect nix's stderr** — upstream master adds `2>/dev/null` to `print-dev-env`; the copy in `~/.config/direnv/lib/hm-nix-direnv.sh` does not. |
| nix on a pipe | one `copying path '…' from '…'…` per store path, one `building '…'…` per derivation, `these N paths will be fetched (…)`, `these N derivations will be built`. No bar: `ProgressBar` sets `active = isTTY` and `draw` returns early otherwise. |
| devenv 2.2.2 on a pipe | `• Name`, `✓ Name in 1.2s`, `✖ Name`, SGR colour always on. The TUI needs stdin *and* stderr to be a terminal (`can_use_stdin_interactively`); the console fallback drops every progress event. The bars seen in a terminal are the TUI. |

So the item is one line, rewritten in place, and each line is *classified*
rather than shown (`classify` in `modules/direnv.lua`). A line becomes a
**phase** (`using flake`, `copying paths`, devenv's `• Building shell`), a
**counter** (`copying path` → paths done; `these 28 paths will be fetched` →
paths expected; the same pair for builds), a **summary** (`Renewed cache`,
`Using cached dev shell`, `unloading`, devenv's `✓ …`), an **error** (`✖ …`,
`error…`, `is blocked`, `failed`, `Falling back`), a **warning**, or nothing.
Anything unrecognised is shown as the phase, so a new message is never lost,
only unformatted. Rendering picks the most informative of what it has: a bar
with counts when a denominator exists, counts alone when only a numerator does,
the phase otherwise; then the elapsed time from the first stderr byte once it
is at least a second. The bar is seven cells of `▰`/`▱` — fidget's own `meter`
glyphs — and is never drawn without a denominator: an indeterminate task gets
the spinner, which is what fidget itself does for LSP progress without a
percentage.

The final line is the errors (up to four, `ERROR`, ttl 10, `✗`), else the
warnings (up to four, `WARN`, ttl 5), else the summary or last phase (`INFO`,
group ttl 3), with the elapsed time appended unless the line already carries
one (devenv's `in 25.1s`).

**Dropped on purpose:** `loading <path>` — the annote is that directory;
`export …` — belt for the toml brace above; `is taking a while to execute` —
the spinner *is* that warning, and `Use CTRL-C` is not advice an editor can
take; the bare paths and `And N more` after `cache invalidated` — the phase
says it; SGR and other CSI/OSC escapes and everything before the last `\r` on
a line — transport, not content.

**Breaks:** quietly, when a producer changes its lines.

- **A nix-direnv bump that adds the upstream `2>/dev/null`** removes every nix
  line: the counters and the `these N paths` denominator vanish and a cold
  `use flake` shows `using flake · 41s` for its whole run. Still true, just
  less. `nix-direnv --version` against upstream is the check.
- **devenv changing its console glyphs** turns `• Building shell` into the
  catch-all phase — shown with the glyph, no longer promoted to a summary on
  `✓`.
- **`hide_env_diff` turned off** would surface `export +A ~PATH` as the phase
  if the `^export` rule were removed with it.

**Also:** the classifier runs on the *cleaned* line — `direnv: ` and
`nix-direnv: ` stripped — so a rule is written against the message, not the
prefix. `log_format` in `direnv.toml` or `DIRENV_LOG_FORMAT` changes the
prefix and nothing else here.

## The bar needs a producer

**Why:** the counters above are a numerator. nix only writes its denominators
and byte counts to a pipe under `--log-format internal-json` — one `@nix {…}`
line per event — and that is a command-line flag with no environment or
`nix.conf` equivalent (`common-args.cc`). nix-direnv calls nix through its
`_nix` wrapper, and direnv sources `~/.config/direnv/direnvrc` *after*
`lib/*.sh`, so a `_nix` redefinition there wins. That redefinition lives in
`~/.dotfiles/flake` (`programs.direnv.stdlib`, branch `direnv-nvim-json-log`)
and is gated twice: `$NVIM` set — Neovim puts its server address into every
job child — and stderr not a TTY. A `:terminal` inside Neovim has `$NVIM` and
a TTY, so its direnv output is untouched; so is every shell.

The consumer is `nix_json` in `modules/direnv.lua`. A `start` records the
activity's type by id. A `result` of type 105 (`resProgress`) carries
`[done, expected, running, failed]`; on the builds aggregate (type 104) and
the copy-paths aggregate (103) those are the counters, and on a file transfer
(101) they are `[bytes, total, 0, 0]`, summed across transfers. A `result` of
type 106 (`resSetExpected`) with fields `[101, n]` is the expected download
total, and expected bytes is the larger of that and the per-transfer sum.
`.narinfo` lookups are not transfers: a cold shell makes hundreds of them, a
few bytes each, and some report no size, which rendered as `33/3 B`. Bytes
show from 1 KiB, and without a denominator when the sum has outrun it. A
`msg` at level 0
is an error, 1 a warning, and anything else goes through the text classifier —
which is where `these N paths will be fetched` still comes from. Field
positions were read off a real `nix --log-format internal-json build`, not
the headers.

**Breaks:** at the seam between the two repositories.

- **Producer switched on before the consumer is deployed.** The flake pins this
  repository by revision. With the direnvrc override active and a pin that
  predates this consumer, every `@nix {…}` line is a transcript line — the
  wall this entry exists to remove, now in JSON. Bump the pin first.
- **The override restates nix-direnv's own flags** (`--no-warn-dirty`,
  `--extra-experimental-features`). A nix-direnv bump that changes them
  changes nothing here and silently diverges there.
- **devenv is not covered, by decision.** Its console renderer drops progress
  events and its TUI cannot run in a pipe; `--trace-to json:stderr` would
  carry the numbers but is undocumented, versioned with the CLI, and turns the
  console lines off. devenv shows phases only.

**Also:** the bar weights each counter by its expected count, and the paths'
share is measured in bytes while a download total is known — the larger of
the two fractions, so seven paths of which one is a 400 MiB NAR fill the bar
as the bytes land rather than sitting at one seventh, and the last unpack
lagging the last byte cannot move it backwards. In JSON mode `copying path`
never arrives as text — it is the `start` text of a type-100 activity — so
the plain-text increments are gated off on `json` and the aggregates are the
only source.
`:lua =_DIRENV.state().json` says whether the producer is active.

**Testing:** `:cd` into a directory with an allowed, warm `.envrc` — no
spinner, `Using cached dev shell` for 3 s. `touch flake.nix` in a `use flake`
project and `:cd` back in: nothing for ~700 ms, then a spinner with
`copying paths · N paths · Ns` counting up, then `Renewed cache · Ns` in place.
`~/Projects/Stash` for devenv: the phases are devenv's own `•` lines and the
close carries devenv's duration, not ours. An `.envrc` holding `sleep 3` is the
cheapest way to see the empty path: nothing, then `loading · 1s` ticking, then
`loaded · 3s`; switch buffers during the sleep and the spinner must stay. A
directory whose `.envrc` has not been allowed gives the `ERROR` path and a `✗`
header, and it stays in `:Fidget history`. `:cd ~` out of a project shows
`unloading`; a `:cd` within the same project shows nothing. Launching nvim from
a shell already inside a direnv directory shows nothing. `:lua =_DIRENV.state()`
shows what the sink has seen, and `:DirenvExport` re-runs an export by hand.
