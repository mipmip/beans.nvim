-- Test helper: build and drive a temporary Beans project on disk.
--
-- Used by the golden-equivalence layer (and available to other specs). All
-- commands run the real `beans` CLI synchronously; callers guard on
-- `vim.fn.executable("beans")` when beans may be absent.

local M = {}

local function run(cmd, cwd)
  local res = vim.system(cmd, { cwd = cwd, text = true }):wait()
  return res.code, res.stdout or "", res.stderr or ""
end

--- Create a fresh temp dir and run `beans init` in it.
--- @return string root
function M.create()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  run({ "beans", "init" }, root)
  return root
end

--- Run an arbitrary beans subcommand in `root`; returns code, stdout, stderr.
function M.beans(root, args)
  local cmd = { "beans" }
  vim.list_extend(cmd, args)
  return run(cmd, root)
end

--- Create a bean; returns { id = <string>, path = <abs file path> }.
--- @param root string
--- @param title string
--- @param flags string[]|nil  e.g. { "-t", "task", "-s", "todo", "-p", "normal" }
function M.create_bean(root, title, flags)
  local cmd = { "beans", "create", title, "--json" }
  vim.list_extend(cmd, flags or {})
  local _, out = run(cmd, root)
  local ok, decoded = pcall(vim.json.decode, out)
  local id = ok and ((decoded.bean and decoded.bean.id) or decoded.id) or nil
  local path = vim.fn.glob(root .. "/.beans/" .. id .. "--*.md")
  return { id = id, path = path }
end

--- Update a bean via the real CLI; returns code, stdout, stderr.
function M.update(root, id, args)
  local cmd = { "beans", "update", id }
  vim.list_extend(cmd, args)
  return run(cmd, root)
end

--- @param path string
--- @return string[] lines
function M.read(path)
  return vim.fn.readfile(path)
end

--- @param path string
--- @param lines string[]
function M.write(path, lines)
  vim.fn.writefile(lines, path)
end

return M
