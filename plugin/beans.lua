-- beans.nvim plugin entry.
--
-- Guarded so it loads at most once. This file must have zero side effects on
-- non-bean buffers: detection, autocmds, commands and keymaps are attached by
-- the plugin's own logic in later milestones, never unconditionally here.

if vim.g.loaded_beans then
  return
end
vim.g.loaded_beans = true
