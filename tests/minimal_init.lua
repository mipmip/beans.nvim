-- Minimal init for headless plenary test runs.
--
-- Usage:
--   nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
--
-- Inside `nix develop` the `nvim` binary already ships plenary and treesitter,
-- so this only needs to put the plugin source itself on the runtimepath.

local cwd = vim.fn.getcwd()
vim.opt.runtimepath:prepend(cwd)

-- Outside `nix develop` (e.g. the stable/nightly CI matrix) plenary is vendored
-- into .deps/plenary.nvim; add it to the runtimepath if present.
local vendored = cwd .. "/.deps/plenary.nvim"
if vim.fn.isdirectory(vendored) == 1 then
  vim.opt.runtimepath:prepend(vendored)
end

-- Load plenary if it is present on the runtimepath (it is, under nix develop).
pcall(vim.cmd, "runtime plugin/plenary.vim")

-- Load the plugin under test.
pcall(vim.cmd, "runtime plugin/beans.lua")
