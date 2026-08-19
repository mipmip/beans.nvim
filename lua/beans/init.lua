-- beans.nvim — a Neovim companion for the Beans flat-file issue tracker.
--
-- This is the public entry point. `setup()` must never error, even when the
-- `beans` binary is missing from $PATH (it degrades to a health-check concern).
-- Real behaviour (detection, wizard, commands, completion) is wired up in later
-- milestones; this milestone only guarantees the module loads and `setup()`
-- is safe to call with or without arguments.

local M = {}

--- Merge user options over defaults and store the resolved config.
--- @param opts table|nil user configuration (see beans-nvim-briefing.md §7.3)
function M.setup(opts)
  local config = require("beans.config")
  M.config = config.merge(opts)
  return M.config
end

return M
