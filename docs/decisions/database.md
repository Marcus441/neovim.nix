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
