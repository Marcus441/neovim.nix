# decisions/direnv

## The stderr sink

**Why:** direnv.vim reports every export by `echom`-ing the lines it collected
on the job's stderr, and it collects them into `s:job_status.stderr` — a
script-local dict no Lua can reach. `modules/direnv.nix` redefines the plugin's
own `direnv#on_stderr` autoload function so the lines land in `g:direnv_stderr`
instead, and a `User DirenvLoaded` autocmd drains that list into fidget.
Nothing in the plugin is patched; the redefinition is an ordinary `function!`
over a global autoload name.

**Breaks:** silently, in three ways.

- **Upstream renaming `direnv#on_stderr`** leaves our definition orphaned and
  the notifications simply stop. Nothing errors — the plugin calls whatever name
  it now uses, and `g:direnv_stderr` stays empty.
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

**Also:** only stderr is diverted. stdout carries the `call setenv(…)` payload
that `direnv#on_exit` feeds to `exec`, which is what actually applies the
environment; `direnv#on_stdout` is untouched for that reason. On Neovim the
plugin never resets `s:job_status` — `job_status_reset` is only called on the
Vim 8 `job_start` path — so its stderr list grows for the life of the session
and each export re-echoes every message before it. Draining `g:direnv_stderr` on
each `DirenvLoaded` is what keeps a notification about the current directory
from carrying every directory visited before it.

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
`_DIRENV_FIDGET_GROUP` first. Registering it only in the spinner looked correct
and was not: a fast export cancels the spinner, so the result notification
created the group from `configs.default` instead, taking the default header,
icon and `ttl = 5`.

**Also breaks by not existing yet, which is why it is defined in `luaConfigRC`
and not, like its two callers, from `VimEnter`.** `DirenvLoaded` is not fired
only by an export. `plugin/direnv.vim` also registers
`autocmd BufEnter * call direnv#extra_vimrc#check()`, and `check()` calls
`direnv#post_direnv_load()` — which fires `DirenvLoaded` — whenever `$DIRENV_DIR`
is non-empty and the buffer sits under it. Launching nvim from a shell direnv
has already loaded satisfies both, out of the inherited environment and before
any export has run. The first `BufEnter` precedes `VimEnter` at startup, so a
`VimEnter`-registered definition left the handler calling a nil global and the
error surfaced as a traceback through `direnv#extra_vimrc#check`. Assigning the
global from `luaConfigRC` is safe in a way the `direnv#on_stderr` redefinition
above is not: nothing sources a Lua global a second time, and package loading
cannot clobber it.

**Also:** three item states, distinguished without borrowing anything from LSP.
`annote_style = "Comment"` mutes an item while it is in flight (a `nil` level
falls through to `annote_style`); a finished item takes the default
`info_style = "Question"`, and a failed one `warn_style = "WarningMsg"`. The
spinner/done icon is the group's `icon`, a `Display` function fidget calls each
render cycle — it animates while any item has no `data` and returns `✓` once
they all do, which is the same contract `fidget.progress.display.for_icon`
implements, reimplemented in four lines rather than imported.

## The spinner

**Why:** a devenv or `use flake` `.envrc` takes seconds to evaluate cold, and
direnv.vim gives no sign it is working. A warm one does not: direnv.vim
debounces on a 500 ms timer before it even calls `jobstart`, so an unconditional
spinner would animate for ~520 ms on *every* `:cd` and carry no information
almost every time. The item is therefore opened from a `vim.defer_fn` at
`direnv_interval + 200`, and a `_DIRENV_EXPORT_ID` generation counter cancels
that pending open — bumped both by a new export and by `DirenvLoaded`. A warm
export shows the result and never a spinner; a slow one shows the spinner and
then the result in place.

**Breaks:** by hanging a spinner on screen forever, whenever something opens an
item that `DirenvLoaded` does not close. Two such paths are handled and neither
is obvious:

- **A directory with no `.envrc`, or one being unloaded, writes nothing to
  stderr.** The `DirenvLoaded` handler must still resolve the item, so the empty
  case removes it rather than returning early.
- **No `direnv` on `$PATH`.** `direnv#export_core` echoes and returns *before*
  `jobstart`, so `DirenvLoaded` never fires at all. The start handler checks
  `executable` first, mirroring the plugin's own check, and schedules nothing.
  This is why the guard is a capability check and not a timeout — it is the only
  path that bails, and it bails deterministically.

**Also:** the empty case does not simply call `remove`. `remove` archives the
item to history unless it is marked `skip_history`, so a bare directory path
would land in `:Fidget history` for every `:cd` past a directory direnv had
nothing to say about. It is marked first, which works only in that direction —
the update branch reads
`item.skip_history = opts.skip_history or item.skip_history`
(`notification/model.lua`), so `true` takes and `false` never could. **That
removal must then be deferred:** `notification.notify` applies its update inside
`vim.schedule` while `notification.remove` mutates synchronously, so an
undeferred remove archives the item before the mark lands. `vim.schedule`
callbacks run in order, which is what puts the two back in sequence.

Every handler calls `require("lz.n").trigger_load("fidget-nvim")` before
touching fidget: it is an `opt` plugin lz.n loads on `LspAttach`, and an export
normally beats any LSP attach, so a cold `require("fidget")` would fail.

**Testing:** `:cd` into a directory with an allowed `.envrc` — no spinner, just
the `loading …` line, because a warm export beats the delay. An `.envrc` holding
`sleep 3` is the cheapest way to see the other path: nothing for ~700 ms, then a
muted spinner under a `direnv` header, then the result in place. `:cd` somewhere
with no `.envrc` and nothing should appear at all, in the window or in
`:Fidget history`. A directory whose `.envrc` has not been allowed gives the
`WARN` path; `direnv: error … is blocked` matches on `error`. Messages no longer
reach `:messages` — the log is `:Fidget history`. `:DirenvExport` re-runs an
export by hand, and `:echo g:direnv_stderr` shows whether the sink is being fed
at all.
