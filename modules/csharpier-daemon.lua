local state = { job = nil, port = nil, failed = false }

local function fail(msg)
  state.failed = true
  vim.schedule(function()
    vim.notify("csharpier server: " .. msg .. "; cs formatting falls back to the LSP", vim.log.levels.WARN)
  end)
end

local function start()
  if state.job or state.failed or vim.fn.executable("csharpier") ~= 1 then
    return
  end
  local banner = ""
  local job = vim.fn.jobstart({ "csharpier", "server" }, {
    on_stdout = function(_, data)
      if state.port then
        return
      end
      banner = banner .. table.concat(data, "\n")
      local port = banner:match("Started on (%d+)")
      if port then
        state.port = tonumber(port)
      end
    end,
    on_exit = function(id, code)
      -- a stale exit after a deliberate respawn must not clobber the new job
      if state.job ~= id then
        return
      end
      local had_port = state.port ~= nil
      state.job, state.port = nil, nil
      if not had_port and not state.failed then
        fail("exited " .. code .. " before printing a port (needs csharpier >= 1.0)")
      end
    end,
  })
  if job > 0 then
    state.job = job
  end
end

local function request(port, ctx, lines, callback)
  local body = vim.json.encode({
    fileName = ctx.filename,
    fileContents = table.concat(lines, "\n") .. "\n",
  })
  vim.system({
    "curl", "-sS", "--max-time", "10",
    "-H", "Content-Type: application/json", "--data-binary", "@-",
    "http://127.0.0.1:" .. port .. "/format",
  }, { stdin = body }, vim.schedule_wrap(function(out)
    if out.code ~= 0 then
      return callback({ unreachable = true, msg = "curl exited " .. out.code })
    end
    local ok, decoded = pcall(vim.json.decode, out.stdout)
    if not ok or type(decoded) ~= "table" or type(decoded.formattedFile) ~= "string"
      or decoded.formattedFile == "" then
      local why = (ok and type(decoded) == "table" and decoded.errorMessage)
        or "no formattedFile in response"
      return callback({ msg = tostring(why) })
    end
    local new_lines = vim.split(decoded.formattedFile, "\r?\n")
    if new_lines[#new_lines] == "" then
      table.remove(new_lines)
    end
    callback(nil, new_lines)
  end))
end

local function format(_, ctx, lines, callback)
  local deadline = vim.uv.now() + 2500
  local function attempt(retried)
    if state.failed then
      return callback("csharpier server unavailable")
    end
    if state.port then
      return request(state.port, ctx, lines, function(err, new_lines)
        if err and err.unreachable and not retried then
          if state.job then
            vim.fn.jobstop(state.job)
          end
          state.job, state.port = nil, nil
          start()
          return attempt(true)
        end
        callback(err and err.msg or nil, new_lines)
      end)
    end
    if vim.uv.now() > deadline then
      return callback("timed out waiting for csharpier server")
    end
    start()
    vim.defer_fn(function()
      attempt(retried)
    end, 50)
  end
  attempt(false)
end

package.loaded["csharpier-daemon"] = {
  state = state,
  start = start,
  format = format,
  available = function()
    return not state.failed
      and vim.fn.executable("csharpier") == 1
      and vim.fn.executable("curl") == 1
  end,
}
