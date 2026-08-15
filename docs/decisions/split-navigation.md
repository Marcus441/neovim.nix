# decisions/split-navigation

## Multiplexer detection

**Why:** smart-splits picks its back-end from the environment, and the tmux
branch is the string test `TERM_PROGRAM == "tmux"` (`smart-splits/config.lua`,
`set_default_multiplexer`). tmux sets that variable itself, but the tmux config
that ships with this machine also carries `set -ga update-environment
TERM_PROGRAM`, which copies the *client's* value — `kitty` — into the session
environment that new panes inherit. Whether tmux's own assignment or the
inherited one wins is a property of tmux's startup order, not something this repo
controls, so the branch is pinned instead: `vim.env.TMUX` is set by tmux for
every pane and by nothing else. `vim.globals` is the right place because it
renders through `toLuaObject` into the `globalsScript` DAG entry, which runs long
before the plugin loads at `DeferredUIEnter`, and `nil` leaves the plugin's own
auto-detection intact for the kitty case.

**Breaks:** silently, and only inside tmux. Losing this line does not error and
does not stop Neovim's own window navigation — it makes Neovim take the kitty
branch in a tmux pane, where it shells out to `kitty @` against the outer
terminal. The keys then move Neovim windows and stop dead at the last one. The
check is `:lua print(require('smart-splits.config').multiplexer_integration)`
inside a tmux pane, which must print `tmux`.

**Also:** the value is a `mkLuaInline`, so it is emitted as a Lua expression
rather than a quoted string. Writing it as a plain Nix string would set the
global to the literal text and the plugin would try to `require` a back-end
named after it.

## The edge behaviour is stop, because kitty cannot wrap

**Why:** the plugin's default is `wrap`, and kitty is the one back-end that
cannot honour it — there is no way to read a kitty window's layout over the CLI,
so the plugin cannot know which pane is opposite. It detects this pairing in
`setup()` and forces `at_edge = "stop"` itself, after a `vim.notify_once` warning.
Setting `stop` here reaches the same behaviour without the notification, and
makes tmux and kitty behave identically at the last split rather than differing
by which terminal happens to be running.

**Breaks:** visibly and harmlessly — a warning toast on every start, and
wrapping that works under tmux but not under kitty. Recorded because the value
looks like a preference and is a compatibility floor.

## The swap binds shadow the buffer picker

**Why:** the plugin's stock swap bindings are `<leader><leader>h/j/k/l`, and
`modules/snacks-picker.nix` already binds `<leader><leader>` on its own to
`Snacks.picker.buffers()`. Neovim resolves that as an ambiguous prefix: the
picker cannot fire until `timeoutlen` has elapsed with no `h`, `j`, `k` or `l`
following. Setting the four to `null` removes them — nvf's smart-splits module
wraps each key in `lib.optional (key != null)`, so a null key emits no `keys`
entry at all rather than an empty one.

**Breaks:** silently, as a delay rather than an error. Restoring any one of the
four puts the stall back on the most-used bind in the config, and nothing in the
build reports it. If a swap bind is ever wanted, give it a prefix that is not
already a complete mapping.

**Also:** `move_cursor_*` (`<C-h/j/k/l>`), `resize_*` (`<A-hjkl>`) and
`move_cursor_previous` (`<C-\>`) are left at their defaults, which is why they
are not named here. Those keys are unbound elsewhere in this repo; `<C-d>`,
`<C-u>`, `<C-=>` and `<C-->` are the only other Ctrl-prefixed normal-mode maps.
The defaults are also conditional on `vim.vendoredKeymaps.enable`, which nvf
defaults to `true` and this repo does not touch — disabling it would silently
unbind all of them.
