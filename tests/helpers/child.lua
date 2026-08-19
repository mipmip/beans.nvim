-- Test helper: spawn and drive a child Neovim over RPC.
--
-- Stub for Milestone 05 (`e2e-ci-release`, layer 4). It will start a real,
-- separate Neovim (`--embed --headless`) with the plugin on runtimepath, drive
-- it with nvim_input (real terminal-style keystrokes), and expose helpers to
-- assert on what the child reports back.

local M = {}

--- @return table child  an RPC handle to a child Neovim (to be implemented)
function M.spawn()
  error("tests.helpers.child.spawn is implemented in Milestone 05")
end

return M
