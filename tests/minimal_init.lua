-- Minimal init for headless plenary test runs.
--
-- Usage:
--   nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
--
-- Inside `nix develop` the `nvim` binary already ships plenary and treesitter,
-- so this only needs to put the plugin source itself on the runtimepath.

local cwd = vim.fn.getcwd()
vim.opt.runtimepath:prepend(cwd)

-- Load plenary if it is present on the runtimepath (it is, under nix develop).
pcall(vim.cmd, "runtime plugin/plenary.vim")

-- Load the plugin under test.
pcall(vim.cmd, "runtime plugin/beans.lua")
