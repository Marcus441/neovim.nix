-- load-bearing: docs/decisions/direnv.md#lines-not-transcripts
local S, generation, timer = nil, 0, nil

local function reset()
  S = {
    cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
    t0 = nil,
    partial = "",
    eof = false,
    open = false,
    phase = nil,
    summary = nil,
    errors = {},
    warns = {},
    paths = { done = 0, expected = 0 },
    builds = { done = 0, expected = 0 },
    json = false,
    acts = {},
    bytes = {},
    bytes_expected = 0,
  }
end
reset()

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function group()
  local frame = require("fidget.spinner").animate("dots", 1)
  require("fidget.notification").set_config("direnv", {
    name = "direnv",
    icon = function(now, items)
      local icon = "✓"
      for _, item in ipairs(items) do
        if not item.data then
          return frame(now)
        elseif item.data == vim.log.levels.ERROR then
          icon = "✗"
        end
      end
      return icon
    end,
    annote_style = "Comment",
    annote_separator = " · ",
    info_style = "Comment",
    ttl = 3,
  }, false)
end

local function elapsed()
  if not S.t0 then
    return nil
  end
  local s = math.floor((vim.uv.hrtime() - S.t0) / 1e9)
  if s < 1 then
    return nil
  elseif s < 60 then
    return s .. "s"
  end
  return ("%dm%02ds"):format(math.floor(s / 60), s % 60)
end

local function count(c, one, many, capped)
  if c.expected > 0 then
    return ("%d/%d %s"):format(c.done, c.expected, capped)
  end
  return c.done .. " " .. (c.done == 1 and one or many)
end

local function bar(frac)
  local n = math.floor(math.min(frac, 1) * 7 + 0.5)
  return ("▰"):rep(n) .. ("▱"):rep(7 - n)
end

local function sizes(done, expected)
  local units, i, ref = { "B", "KiB", "MiB", "GiB" }, 1, math.max(done, expected)
  while ref >= 1024 and i < #units do
    ref, i = ref / 1024, i + 1
  end
  local function f(n)
    n = n / 1024 ^ (i - 1)
    return i == 1 and ("%d"):format(n) or ("%.1f"):format(n)
  end
  if expected > 0 then
    return ("%s/%s %s"):format(f(done), f(expected), units[i])
  end
  return f(done) .. " " .. units[i]
end

local function render()
  local bdone, bexp = 0, 0
  for _, b in pairs(S.bytes) do
    bdone, bexp = bdone + b[1], bexp + b[2]
  end
  bexp = math.max(bexp, S.bytes_expected)
  local parts, counts, done, total = {}, {}, 0, 0
  if S.paths.done + S.paths.expected > 0 then
    table.insert(counts, count(S.paths, "path", "paths", "paths"))
  end
  if S.builds.done + S.builds.expected > 0 then
    table.insert(counts, count(S.builds, "build", "builds", "built"))
  end
  for _, c in ipairs({ S.paths, S.builds }) do
    if c.expected > 0 then
      local frac = c.done / c.expected
      if c == S.paths and bexp >= 1024 then
        frac = math.max(frac, math.min(bdone / bexp, 1))
      end
      done, total = done + c.expected * frac, total + c.expected
    end
  end
  if total > 0 then
    table.insert(parts, bar(done / total) .. " " .. table.concat(counts, " · "))
  elseif #counts > 0 then
    vim.list_extend(parts, counts)
  else
    table.insert(parts, S.phase or "loading")
  end
  if bdone >= 1024 then
    table.insert(parts, sizes(bdone, bexp >= bdone and bexp or 0))
  end
  local e = elapsed()
  if e then
    table.insert(parts, e)
  end
  return table.concat(parts, " · ")
end

local function show(update_only)
  require("fidget").notify(render(), nil, {
    group = "direnv",
    key = "direnv",
    annote = S.cwd,
    update_only = update_only,
    ttl = math.huge,
  })
end

local function clean(line)
  line = line:match("[^\r]*$")
  line = line:gsub("\27%[[%d;?]*%a", ""):gsub("\27%].-\7", "")
  line = line:gsub("^direnv: ", ""):gsub("^nix%-direnv: ", "")
  return vim.trim(line)
end

local classify

-- load-bearing: docs/decisions/direnv.md#the-bar-needs-a-producer
local function nix_json(text)
  local ok, m = pcall(vim.json.decode, text)
  if not ok or type(m) ~= "table" then
    return
  end
  S.json = true
  local f = m.fields or {}
  if m.action == "start" then
    if m.type ~= 101 or not tostring(f[1] or ""):match("%.narinfo$") then
      S.acts[m.id] = m.type
    end
    if m.type == 100 or m.type == 108 then
      S.phase = "copying paths"
    elseif m.type == 105 then
      S.phase = "building"
    elseif m.type == 112 or m.type == 113 then
      S.phase = "fetching"
    elseif m.type == 0 and (m.text or ""):match("^evaluating") then
      S.phase = "evaluating"
    end
  elseif m.action == "result" and m.type == 105 then
    local t = S.acts[m.id]
    if t == 104 then
      S.builds.done, S.builds.expected = f[1], f[2]
    elseif t == 103 then
      S.paths.done, S.paths.expected = f[1], f[2]
    elseif t == 101 then
      S.bytes[m.id] = { f[1], f[2] }
    end
  elseif m.action == "result" and m.type == 106 and f[1] == 101 then
    S.bytes_expected = f[2]
  elseif m.action == "stop" then
    S.acts[m.id] = nil
  elseif m.action == "msg" and type(m.msg) == "string" then
    if m.level == 0 then
      table.insert(S.errors, (m.msg:gsub("^error: ", "")))
    elseif m.level == 1 then
      table.insert(S.warns, m.msg)
    else
      classify(m.msg)
    end
  end
end

function classify(raw)
  local line = clean(raw)
  if line:sub(1, 5) == "@nix " then
    return nix_json(line:sub(6))
  end
  if line == "" or line:match("^loading ") or line:match("^export ")
    or line:find("is taking a while to execute", 1, true)
    or line:match("^/") or line:match("^And %d+ more") then
    return
  end
  if line:match("^unloading") then
    S.summary = "unloading"
    return
  end
  local using = line:match("^using (.+)")
  if using then
    S.phase = "using " .. using
    return
  end
  local n = line:match("^these (%d+) paths will be fetched")
    or (line:match("^this path will be fetched") and 1)
  if n then
    S.paths.expected = tonumber(n)
    return
  end
  n = line:match("^these (%d+) derivations will be built")
    or (line:match("^this derivation will be built") and 1)
  if n then
    S.builds.expected = tonumber(n)
    return
  end
  if line:match("^copying path") then
    S.paths.done = S.paths.done + (S.json and 0 or 1)
    S.phase = "copying paths"
    return
  end
  if line:match("^building '") then
    S.builds.done = S.builds.done + (S.json and 0 or 1)
    S.phase = "building"
    return
  end
  local word = line:match("^(fetching)") or line:match("^(downloading)")
    or line:match("^(unpacking)") or line:match("^(evaluating)")
  if word then
    S.phase = word
    return
  end
  if line:match("^cache invalidated") then
    S.phase = "cache invalidated"
    return
  end
  if line:match("^Renewed cache") or line:match("^Using cached dev shell") then
    S.summary = line
    return
  end
  local started = line:match("^• (.+)")
  if started then
    S.phase = started
    return
  end
  local finished = line:match("^✓ (.+)")
  if finished then
    S.summary = finished
    return
  end
  local failed = line:match("^✖ (.+)")
  if failed or line:match("^error") or line:find("is blocked", 1, true)
    or line:find("failed", 1, true) or line:find("Falling back", 1, true) then
    table.insert(S.errors, failed or line)
    return
  end
  if line:match("^warning") then
    table.insert(S.warns, line)
    return
  end
  S.phase = line
end

local function final()
  local msg, level, ttl
  if #S.errors > 0 then
    msg, level, ttl = table.concat(vim.list_slice(S.errors, 1, 4), "\n"), vim.log.levels.ERROR, 10
  elseif #S.warns > 0 then
    msg, level, ttl = table.concat(vim.list_slice(S.warns, 1, 4), "\n"), vim.log.levels.WARN, 5
  else
    msg, level, ttl = S.summary or S.phase or (S.open and "loaded"), vim.log.levels.INFO, 0
  end
  if not msg then
    return nil
  end
  local e = elapsed()
  if e and level == vim.log.levels.INFO and not msg:find(" in %d") then
    msg = msg .. " · " .. e
  end
  return msg, level, ttl
end

local function on_stderr(data)
  if #data == 1 and data[1] == "" then
    S.eof = true
    return
  end
  S.t0 = S.t0 or vim.uv.hrtime()
  data[1] = S.partial .. data[1]
  S.partial = table.remove(data)
  for _, line in ipairs(data) do
    classify(line)
  end
  if S.open then
    show(true)
  end
end

local function start()
  if vim.fn.executable(vim.g.direnv_cmd or "direnv") ~= 1 then
    return
  end
  generation = generation + 1
  local gen = generation
  stop_timer()
  reset()
  vim.defer_fn(function()
    if generation ~= gen or S.eof then
      return
    end
    require("lz.n").trigger_load("fidget-nvim")
    group()
    require("fidget.notification").remove("direnv", "direnv")
    S.open = true
    show(false)
    timer = vim.uv.new_timer()
    timer:start(1000, 1000, vim.schedule_wrap(function()
      if S.open then
        show(true)
      end
    end))
  end, (vim.g.direnv_interval or 500) + 200)
end

local function loaded()
  if not S.eof then
    return
  end
  if S.partial ~= "" then
    classify(S.partial)
    S.partial = ""
  end
  generation = generation + 1
  stop_timer()
  local msg, level, ttl = final()
  S.open, S.eof = false, false
  if not msg then
    return
  end
  require("lz.n").trigger_load("fidget-nvim")
  group()
  require("fidget").notify(msg, level, {
    group = "direnv",
    key = "direnv",
    annote = S.cwd,
    data = level,
    ttl = ttl,
  })
end

_DIRENV = {
  start = start,
  on_stderr = on_stderr,
  loaded = loaded,
  render = render,
  final = final,
  state = function()
    return S
  end,
}
