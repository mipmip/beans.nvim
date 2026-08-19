-- Test helper: spawn and drive a child Neovim over RPC (layer-4 e2e).
--
-- Starts a real, separate Neovim (`--embed --headless`) and drives it with
-- nvim_input (real terminal-style keystrokes) — the only layer that catches
-- keymaps that never attached, a float that failed to open, an autocmd that
-- fired twice, or mode-state bugs at finish. Inside `nix develop` the `nvim` on
-- PATH already carries beans.nvim + plenary on its runtimepath and the `beans`
-- binary in its environment.

local M = {}

--- Spawn and initialise a child Neovim.
--- @param opts table|nil  { setup = <lua string passed to require('beans').setup> }
--- @return table|nil child  handle, or nil if a child could not be started
function M.spawn(opts)
  opts = opts or {}
  local ok, job = pcall(vim.fn.jobstart, { "nvim", "--embed", "--headless" }, { rpc = true })
  if not ok or type(job) ~= "number" or job <= 0 then
    return nil
  end

  local child = { job = job }

  function child.request(method, ...)
    return vim.rpcrequest(job, method, ...)
  end

  --- Run Lua in the child; returns whatever the code returns.
  function child.exec_lua(code, args)
    return vim.rpcrequest(job, "nvim_exec_lua", code, args or {})
  end

  --- Evaluate a Lua expression in the child and return its value.
  function child.eval(expr)
    return child.exec_lua("return (" .. expr .. ")")
  end

  --- Feed real terminal keystrokes (supports <Tab>, <Esc>, <CR>, <C-n>, …).
  function child.input(keys)
    vim.rpcrequest(job, "nvim_input", keys)
  end

  --- Poll a boolean Lua expression in the child until true or timeout.
  function child.await(expr, timeout)
    return vim.wait(timeout or 2000, function()
      local pok, res = pcall(child.eval, expr)
      return pok and res == true
    end, 20)
  end

  function child.get_lines()
    return child.exec_lua("return vim.api.nvim_buf_get_lines(0, 0, -1, false)")
  end

  --- Does the child have any floating window open?
  function child.has_float()
    return child.eval(
      "(function() for _,w in ipairs(vim.api.nvim_list_wins()) do "
        .. "local c=vim.api.nvim_win_get_config(w) if c.relative and c.relative ~= '' then return true end "
        .. "end return false end)()"
    ) == true
  end

  function child.stop()
    pcall(vim.fn.jobstop, job)
  end

  -- Initialise the plugin in the child.
  local setup_arg = opts.setup or ""
  child.exec_lua("require('beans').setup(" .. setup_arg .. ")")

  return child
end

return M
