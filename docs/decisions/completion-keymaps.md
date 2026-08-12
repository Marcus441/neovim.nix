# decisions/completion-keymaps

## Nulling nvf's mappings

**Why:** the keys the completion menu answers to are set in three places, and
only one of them is safe to write in. blink's `keymap.preset = "default"` is
resolved inside the plugin at runtime and supplies `<C-n>`, `<C-p>`, `<C-y>`,
`<Up>`, `<Down>`, `<C-b>` and `<C-k>`. nvf writes its *own* keys into
`setupOpts.keymap` from `vim.autocomplete.blink-cmp.mappings.*` — `<CR>` accept,
`<Tab>` select-next, `<S-Tab>` select-prev — and an explicit key beats a preset
key, so nvf's three won. Anything this repo adds under `setupOpts.keymap."<X>"`
does not replace nvf's list, it **concatenates** with it, and module order then
picks which definition the key obeys. That is the trap `03123e9` closed by
deleting every override this repo had, and the reason the fix here is `confirm =
null`, `next = null`, `previous = null` instead: `blink-cmp/config.nix` filters
null mappings out before emitting the table, so the key is *absent* rather than
contested, and blink's preset fills the hole. `<CR>` ends up bound by nothing and
`<Tab>`/`<S-Tab>` by the preset's snippet-only pair, which is the requested
behaviour reached without this repo naming a single key in insert mode.

**Breaks:** silently, and only on the way back. Restoring `mappings.next` while
leaving the `cmdline.keymap."<Tab>"` entry below it gives that key two
definitions again — nvf's and ours — with no error and no warning; whichever
module sorts first decides whether `<Tab>` completes or selects on the `:` line.
The two move together or not at all. Reading the built `init.lua` is the check:
every key inside `["keymap"]` and `["cmdline"]["keymap"]` must appear once.

**Also:** the `cmdline` entries exist only to hold that mode still. Nulling
`next`/`previous` strips `<Tab>`/`<S-Tab>` from the cmdline table too, and the
preset's replacement does not survive there — blink drops any cmdline mapping
whose commands are all snippet commands plus `fallback` (`has_insert_command`),
so `<Tab>` would have quietly stopped completing on the `:` line. The lists
restored are nvf's former ones verbatim, and with nvf's own definitions now
filtered out they are the sole definition for those keys.

## Ghost text previews without a selection

**Why:** `completion.list.selection.preselect = false` means nothing is selected
when the menu opens, and ghost text renders the *selected* item — so
`ghost_text.enabled = true` on its own shows nothing until `<C-n>` is pressed,
which reads as the setting not having worked. `show_without_selection = true` is
what makes the top match preview immediately. It pairs with `auto_insert =
false`: the preview is virtual text, so stepping through the menu never puts
anything in the buffer until `<C-y>`.

**Breaks:** visibly, which is why neither value carries a pointer of its own.
The pair is noted here because the two options look independent and are not.
