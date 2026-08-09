# Find comment runs longer than two lines inside '' blocks.
#
# Text in a '' block is content: it ships into the generated init.lua, the
# treesitter query file, or a wrapper script. CLAUDE.md 10 caps a comment there
# at two lines -- a label, not an argument. This finds the violations.
#
# Two passes. The first lexes Nix to learn which lines sit inside an indented
# string; a '--' outside one is a Nix range operator and a '#' inside a "..." is
# data, and neither is ours. The second classifies those lines by the comment
# syntax of whatever language the block holds: '--' and '--[[ ]]' for Lua,
# '#' for shell, '//' and '/* */' for C-like.
#
# Not treated as comments: ';;' opening a treesitter query, because ';; extends'
# is a directive the query file needs.

BEGIN { RS = "\0" }

{
  src = $0
  n = length(src)

  # ---- pass 1: which lines are inside a '' block ----
  top = 1; mode[1] = "code"; depth[1] = 0
  line = 1
  i = 1
  while (i <= n) {
    c   = substr(src, i, 1)
    two = substr(src, i, 2)

    if (mode[top] == "ind") inind[line] = 1

    if (c == "\n") { line++; i++; continue }

    if (mode[top] == "code") {
      if (c == "#") { while (i <= n && substr(src, i, 1) != "\n") i++; continue }
      if (two == "/*") {
        i += 2
        while (i <= n && substr(src, i, 2) != "*/") { if (substr(src, i, 1) == "\n") line++; i++ }
        i += 2; continue
      }
      if (two == "''") { top++; mode[top] = "ind"; i += 2; continue }
      if (c == "\"")   { top++; mode[top] = "dq";  i += 1; continue }
      if (c == "{") { depth[top]++; i++; continue }
      if (c == "}") { depth[top]--; if (depth[top] < 0 && top > 1) top--; i++; continue }
      i++; continue
    }

    if (mode[top] == "dq") {
      if (c == "\\")   { if (substr(src, i+1, 1) == "\n") line++; i += 2; continue }
      if (two == "${") { top++; mode[top] = "code"; depth[top] = 0; i += 2; continue }
      if (c == "\"")   { top--; i++; continue }
      i++; continue
    }

    # mode[top] == "ind"
    if (two == "''") {
      nx = substr(src, i+2, 1)
      if (nx == "'" || nx == "$") { i += 3; continue }   # '''  ''$
      if (nx == "\\")             { i += 4; continue }   # ''\x
      top--; i += 2; continue
    }
    if (two == "${") { top++; mode[top] = "code"; depth[top] = 0; i += 2; continue }
    i++
  }

  # ---- pass 2: comment runs on those lines ----
  nl = split(src, L, "\n")
  run = 0; start = 0; inblock = 0; inlua = 0

  for (k = 1; k <= nl; k++) {
    s = L[k]
    gsub(/^[ \t]+/, "", s)

    if (!inind[k]) { flush(k); continue }

    if (inblock) {                      # inside a /* ... */
      run++
      if (s ~ /\*\//) inblock = 0
      continue
    }

    if (inlua) {                        # inside a --[[ ... ]]
      run++
      if (s ~ luaclose) inlua = 0
      continue
    }

    if (s ~ /^--\[=*\[/) {              # opens a Lua long comment
      if (!run) start = k
      run++
      luaclose = luacloser(s)
      if (s !~ luaclose) inlua = 1
      continue
    }

    if (s ~ /^--/) { if (!run) start = k; run++; continue }

    if (s ~ /^\/\*/) {                  # opens a C block comment
      if (!run) start = k
      run++
      if (s !~ /\*\//) inblock = 1
      continue
    }

    if (s ~ /^\/\//) { if (!run) start = k; run++; continue }

    if (s ~ /^#/) {
      # not a comment: shebang, C preprocessor, CSS colour, CSS selector
      if (s ~ /^#!/)                                          { flush(k); continue }
      if (s ~ /^#(define|include|if|ifdef|ifndef|else|elif|endif|pragma|undef)\b/) { flush(k); continue }
      if (s ~ /^#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?([0-9a-fA-F]{2})?[^0-9a-zA-Z]/)    { flush(k); continue }
      if (s ~ /^#[A-Za-z_-][A-Za-z0-9_-]*[ \t]*[,{>:.]/)      { flush(k); continue }
      if (!run) start = k
      run++
      continue
    }

    flush(k)
  }
  flush(nl + 1)
}

# The closing bracket of a Lua long comment matches its opening level:
# --[[ closes with ]], --[==[ closes with ]==].
function luacloser(s,   m, eq, out) {
  m = s
  sub(/^--\[/, "", m)
  eq = 0
  while (substr(m, eq + 1, 1) == "=") eq++
  out = "\\]"
  while (eq-- > 0) out = out "="
  return out "\\]"
}

function flush(k) {
  if (run > 2) {
    printf "%s:%d: comment run of %d lines inside a '' block (cap is 2)\n", FILENAME, start, run
    bad++
  }
  run = 0; inblock = 0; inlua = 0
}

END { exit (bad > 0) }
