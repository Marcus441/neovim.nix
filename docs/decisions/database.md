# decisions/database

## the clients are pinned in dev

**Why:** vim-dadbod is not a database driver — every adapter shells out to a
client to run a query, `sqlcmd` for SQL Server and `psql` for Postgres. `gui` is
launched from
`programs.neovide.settings.neovim-bin` and `full` from a bare terminal, so
neither has a devshell to supply them, and the build that actually carries
dadbod would open an empty drawer on a clean machine. Measured 2026-09-06, the
pair costs **48 MiB** on `gui` — 6696 → 6744 MiB.

**Breaks:** loudly, which is why this is an entry about the *cost* rather than
the pin. Dropping either package means every query against that engine fails
with dadbod's own "command not found". The silent half is the closure:
`postgresql` is a server package taken for one client binary, and there is no
client-only output to narrow it to.

**Also:** no `preferPathExe` wrapper is needed here, which is the part that
looks wrong and is not. mnw *appends* — `wrapper.nix:91` is
`vim.env.PATH = vim.env.PATH .. ":" .. makeBinPath (…extraBinPath)` — so a
project's own `psql` inside a devshell still wins and these only fill the gap.
That is `prefer-path.md#silent-fallback` behaviour obtained for free, and it is
the reason `min` can be left out entirely rather than pinned and overridden.
The 48 MiB is also far under the 212 MiB the two closures suggest, because
`icu4c` is already paid for by `dotnet-sdk_10` in `dev`.

## a query buffer is saved, not executed

**Why:** `vim-dadbod-ui` defaults `g:db_ui_execute_on_save` to 1
(`plugin/db_ui.vim:26`) and hooks `BufWritePost` (`autoload/db_ui/query.vim:181`),
so every `:w` in a scratch query buffer runs it against whatever connection the
buffer is bound to. That is a live production database as readily as a local
one, triggered by the most reflexive keystroke in the editor. It is off here,
and `<Leader>S` — dadbod-ui's own buffer-local bind, `ftplugin/sql.vim` — is the
only thing that executes.

**Breaks:** loudly in the direction that matters and quietly in the other.
Turning it back on is immediately obvious. Leaving it on while SQL also has a
formatter is the bad case: `modules/formatter.nix` gates `format_on_save` on
`vim.g.disable_autoformat` alone, with no filetype exclusion, so a single `:w`
would reformat the buffer on `BufWritePre` and run it on `BufWritePost`.

**Also:** dadbod-ui's three SQL-buffer binds are the plugin's, not ours, which
is why they were missing from the README table for as long as they have worked.
With execute-on-save off, `<Leader>S` stops being a convenience and becomes the
only route, so the table has to carry it. Note too that dadbod's query path does
not pass `-X` (`autoload/db/adapter/postgresql.vim:16-19`), so a `\pset` in
`~/.psqlrc` reaches the `dbout` buffer.

## sql declines sqls

**Why:** `vim.languages.sql.lsp.enable` defaults to `config.vim.lsp.enable`,
which `modules/lsp.nix` sets true in `dev`, so enabling SQL at all switches
`sqls` back on. `4c8b517` removed it for conflicting with dadbod and left no
body explaining how, so: `sqls` claims `sql`, `mysql` and `plsql`, carries its
own `config.yml` of database connections, and serves completion from them —
duplicating the job `vim.g.dbs` and `vim-dadbod-completion` already do from the
secrets file, against a second and separately-configured set of credentials.

**Breaks:** loudly at first and confusingly after. The server attaches, and
completion in a query buffer starts returning columns from whatever `sqls`
itself is connected to rather than the connection the buffer is bound to. The
`omnifunc` line in `modules/database.nix` and the blink `per_filetype` entry
both assume dadbod is the only source of schema.

**Also:** plain `false`, not `lib.mkDefault false`. nvf's own default here is
`mkOptionDefault` at 1500, so an ordinary value overrides it without help, and
a plain `false` errors the day something in `dev` disagrees — which is the good
failure. A `mkDefault` nothing ever overrides is the noise
`.claude/rules/evaluation-hazards.md` warns about.

## sqruff refuses an unknown dialect

**Why:** `sqruff fix` rewrites the file in place and does **not** refuse SQL it
misparses. Measured 2026-09-06 at its default `ansi` dialect, it turned
`SELECT TOP 10 [Name]` into `SELECT TOP 10[Name]` — it does not know `TOP`, so
it closed the space it thought was spurious. The same file under
`--dialect tsql` formats correctly. Postgres fares better but not well:
`data->>'name'` becomes `data ->>'name'`. So the formatter is gated on knowing
the dialect. `modules/languages/sql-dialect.lua` answers in order:
`vim.b.sql_dialect`, `vim.g.sql_dialect`, then the engine read off `b:db` —
dadbod-ui sets it to the connection URL on every query buffer, so a scratch
query formats as the dialect of the server it is bound to with nothing
configured. Failing all three, a `.sqruff` found by `vim.fs.root` counts, and
`conform` is told the formatter is unavailable when nothing answers at all.

**Breaks:** silently, and in the worst possible place. Dropping the `condition`
does not fail a build or raise an error; it means every `:w` on a T-SQL file
quietly reformats it as ANSI. `format_on_save` in this file gates on
`vim.g.disable_autoformat` alone, so there is nothing else standing between an
unrecognised dialect and the buffer.

**Also:** `sqruff dialects` lists both `tsql` and `postgres`, which is why it
was chosen over `sqlfluff` — one 20 MiB Rust binary covers both engines, which
is the whole point when the two are worked on side by side. The cost of the
gate is that a `.sql` file on disk, opened outside a DBUI connection and in a
project with no `.sqruff`, formats nowhere until `vim.g.sql_dialect` is set.
That is the intended trade: no formatting is recoverable, ANSI-mangled T-SQL
committed by a format-on-save is not.
