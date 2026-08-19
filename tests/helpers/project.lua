-- Test helper: build a temporary Beans project on disk.
--
-- Stub for Milestone 05 (`unit-wizard-tests` / `golden-equivalence`). It will
-- create a temp dir, run `beans init` (or lay down a .beans.yml + bean files),
-- and return paths so specs can exercise detection and frontmatter editing
-- against a realistic layout.

local M = {}

--- @return string root  path to a temporary Beans project (to be implemented)
function M.create()
  error("tests.helpers.project.create is implemented in Milestone 05")
end

return M
