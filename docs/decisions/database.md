# decisions/database

## enumeration reports instead of returning empty

**Why:** `modules/database.nix` reads a secrets file and shells out to a
database client, and `.claude/rules/lua-in-nix.md` asks that the third thing in
the tree of that shape report rather than fail to an empty table. Every exit now
names itself: a missing secrets file, unparseable JSON, a client that is not on
`$PATH`, an unknown `type`, and a non-zero client exit quoting its stderr.

**Breaks:** silently, which is the whole point of the entry. Deleting any one
`vim.notify` here leaves `vim.g.dbs` empty and `:DBUIToggle` opening an empty
drawer, with nothing anywhere saying whether the file was missing, the password
was wrong, or the binary was absent. Those four causes are indistinguishable
from the drawer.

**Also:** `6c04be5` removed the secrets-file warnings for being noise on every
launch, and it was right at the time — `refresh()` still ran at startup. It
dropped that auto-refresh in the same commit, so the warnings now only fire when
someone typed `:DBRefresh`, which is exactly when they are wanted. Restoring
them is not a re-litigation of that commit; it is the consequence of its other
half.

## the enumerated url is percent-encoded, the drawer name is not

**Why:** dadbod parses a connection URL with its own regex
(`autoload/db/url.vim`), which forbids a raw `@` or `/` in the password and
percent-decodes user, password, host and path afterwards. `vim.uri_encode` is
not enough: at its default RFC-3986 it leaves `@`, `:` and `/` untouched, so a
password containing any of them produced a URL that parsed into the wrong host
and a database name containing a space produced an invalid URI. The strict
unreserved-set encoder in the file exists because the stdlib one is too lax
here.

**Breaks:** in two directions, neither of them loudly. A password with an `@`
addresses a host that is not yours and fails to connect; a database name with a
space simply never appears, which is how the old `[:%s]` filter hid this for as
long as it existed. The drawer label deliberately keeps the raw name — it is
read by a human, never parsed.

**Also:** the same encoding is correct for both engines. libpq percent-decodes a
URI it is handed as `--dbname`, and dadbod decodes before building `sqlcmd`'s
`-U`/`-d` argv, so one encoder serves both rather than one rule per adapter.

## the clients are pinned in dev

**Why:** vim-dadbod is not a database driver — every adapter shells out, `sqlcmd`
for SQL Server and `psql` for Postgres, and `modules/database.nix` shells out to
the same two to enumerate. `gui` is launched from
`programs.neovide.settings.neovim-bin` and `full` from a bare terminal, so
neither has a devshell to supply them, and the build that actually carries
dadbod would open an empty drawer on a clean machine. Measured 2026-09-06, the
pair costs **48 MiB** on `gui` — 6696 → 6744 MiB.

**Breaks:** loudly now, which is why this is an entry about the *cost* rather
than the pin. Dropping either package leaves the enumerator reporting
`[db] psql is not on $PATH` rather than failing to an empty table. The silent
half is the closure: `postgresql` is a server package taken for one client
binary, and there is no client-only output to narrow it to.

**Also:** no `preferPathExe` wrapper is needed here, which is the part that
looks wrong and is not. mnw *appends* — `wrapper.nix:91` is
`vim.env.PATH = vim.env.PATH .. ":" .. makeBinPath (…extraBinPath)` — so a
project's own `psql` inside a devshell still wins and these only fill the gap.
That is `prefer-path.md#silent-fallback` behaviour obtained for free, and it is
the reason `min` can be left out entirely rather than pinned and overridden.
The 48 MiB is also far under the 212 MiB the two closures suggest, because
`icu4c` is already paid for by `dotnet-sdk_10` in `dev`.
