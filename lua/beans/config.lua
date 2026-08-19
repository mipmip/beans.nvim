-- beans.config — defaults and merge.
--
-- The full default table (beans-nvim-briefing.md §7.3) and validate-on-setup
-- behaviour are implemented in Milestone 04 (`configuration` capability). This
-- skeleton provides just enough for `require("beans").setup()` to succeed with
-- or without arguments and for a partial table to merge without wiping siblings.

local M = {}

--- The recommended defaults. Milestone 04 fills this in verbatim from §7.3.
M.defaults = {}

--- Deep-merge user options over the defaults.
--- Uses "force" so partial user tables override only the keys they set.
--- @param opts table|nil
--- @return table
function M.merge(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
