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

local function render()
  local parts, counts = {}, {}
  if S.paths.done + S.paths.expected > 0 then
    table.insert(counts, count(S.paths, "path", "paths", "paths"))
  end
  if S.builds.done + S.builds.expected > 0 then
    table.insert(counts, count(S.builds, "build", "builds", "built"))
  end
  local done, total = 0, 0
  for _, c in ipairs({ S.paths, S.builds }) do
    if c.expected > 0 then
      done, total = done + c.done, total + c.expected
    end
  end
  if total > 0 then
    table.insert(parts, bar(done / total) .. " " .. table.concat(counts, " · "))
  elseif #counts > 0 then
    vim.list_extend(parts, counts)
  else
    table.insert(parts, S.phase or "loading")
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

local function classify(raw)
  local line = clean(raw)
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
    S.paths.done = S.paths.done + 1
    S.phase = "copying paths"
    return
  end
  if line:match("^building '") then
    S.builds.done = S.builds.done + 1
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
