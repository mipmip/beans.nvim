-- beans.cli — async wrapper around the `beans` CLI.
--
-- All reads are asynchronous via `vim.system`; this module NEVER calls
-- `:wait()` on the main loop (briefing §5.3). Every command runs with `cwd` set
-- to the project root and may carry a `--beans-path` override.

local M = {}

--- Build the argv for a beans invocation.
--- @param config table  resolved plugin config (for `executable`)
--- @param args string[]  command + flags, e.g. { "update", "--help" }
--- @param opts table|nil { beans_path = <string> }
--- @return string[]
local function build_cmd(config, args, opts)
  local exe = (config and config.executable) or "beans"
  local cmd = { exe }
  vim.list_extend(cmd, args)
  if opts and opts.beans_path then
    table.insert(cmd, "--beans-path")
    table.insert(cmd, opts.beans_path)
  end
  return cmd
end

--- Run a beans command asynchronously.
--- @param config table
--- @param args string[]
--- @param opts table|nil { cwd = <string>, beans_path = <string>, timeout = <ms> }
--- @param callback fun(result: { code: integer, stdout: string, stderr: string, ok: boolean })
function M.run(config, args, opts, callback)
  opts = opts or {}
  local cmd = build_cmd(config, args, opts)

  local ok, err = pcall(function()
    vim.system(cmd, {
      cwd = opts.cwd,
      text = true,
      timeout = opts.timeout or (config and config.timeout) or 5000,
    }, function(obj)
      -- Marshal back onto the main loop before invoking the callback.
      vim.schedule(function()
        callback({
          code = obj.code,
          stdout = obj.stdout or "",
          stderr = obj.stderr or "",
          ok = obj.code == 0,
        })
      end)
    end)
  end)

  if not ok then
    -- e.g. executable not found — degrade rather than throw.
    vim.schedule(function()
      callback({ code = -1, stdout = "", stderr = tostring(err), ok = false })
    end)
  end
end

--- Run a beans command and decode its stdout as JSON.
--- @param config table
--- @param args string[]
--- @param opts table|nil
--- @param callback fun(decoded: any|nil, result: table)
function M.run_json(config, args, opts, callback)
  M.run(config, args, opts, function(result)
    if not result.ok or result.stdout == "" then
      callback(nil, result)
      return
    end
    local ok, decoded = pcall(vim.json.decode, result.stdout)
    if ok then
      callback(decoded, result)
    else
      callback(nil, result)
    end
  end)
end

return M
