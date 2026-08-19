-- beans.project — project root detection and .beans.yml reading.
--
-- Walks upward from a path looking for `.beans.yml` (falling back to a `.beans/`
-- directory), and reads the single key the plugin needs, `beans.path`, with a
-- tiny hand-rolled parser (no YAML dependency, per briefing §2.4).

local M = {}

local uv = vim.uv or vim.loop

--- @param path string
--- @return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

--- @param path string
--- @return boolean
local function is_dir(path)
  local st = uv.fs_stat(path)
  return st ~= nil and st.type == "directory"
end

--- Directory containing `path` (which may be a file or a directory).
--- @param path string
--- @return string
local function dir_of(path)
  if is_dir(path) then
    return path
  end
  return vim.fs.dirname(path)
end

--- Walk upward from `start` looking for the project root.
--- A root is a directory that contains `.beans.yml`, or (fallback) a `.beans/`
--- directory.
--- @param start string  a file or directory path
--- @return string|nil root  the project root, or nil if none found
function M.find_root(start)
  if not start or start == "" then
    return nil
  end
  local dir = dir_of(vim.fs.normalize(start))

  -- Prefer a directory carrying `.beans.yml`.
  local yml = vim.fs.find(".beans.yml", { path = dir, upward = true, type = "file" })[1]
  if yml then
    return vim.fs.dirname(yml)
  end

  -- Fall back to a `.beans/` directory.
  local beans = vim.fs.find(".beans", { path = dir, upward = true, type = "directory" })[1]
  if beans then
    return vim.fs.dirname(beans)
  end

  return nil
end

--- Read `beans.path` from `<root>/.beans.yml`. Hand-rolled: find the `path:`
--- entry indented under the top-level `beans:` key. Defaults to `.beans`.
--- @param root string
--- @return string beans_path  the configured path (default ".beans")
function M.read_beans_path(root)
  local default = ".beans"
  local yml = root .. "/.beans.yml"
  if not exists(yml) then
    return default
  end

  local ok, lines = pcall(vim.fn.readfile, yml)
  if not ok or type(lines) ~= "table" then
    return default
  end

  local in_beans_block = false
  for _, line in ipairs(lines) do
    -- Top-level `beans:` key (no leading whitespace).
    if line:match("^beans:%s*$") then
      in_beans_block = true
    elseif line:match("^%S") then
      -- Any other top-level key ends the beans block.
      in_beans_block = false
    elseif in_beans_block then
      local value = line:match("^%s+path:%s*(.+)%s*$")
      if value then
        -- Strip surrounding quotes if present.
        value = value:gsub("^[\"']", ""):gsub("[\"']%s*$", "")
        value = value:gsub("%s+$", "")
        if value ~= "" then
          return value
        end
      end
    end
  end

  return default
end

--- Resolve the bean directory for a project root.
--- @param root string
--- @return string beans_dir  absolute path to the bean directory
function M.beans_dir(root)
  local p = M.read_beans_path(root)
  if p:match("^/") then
    return vim.fs.normalize(p)
  end
  return vim.fs.normalize(root .. "/" .. p)
end

--- Locate the project for a given buffer path.
--- @param path string  a file or directory path
--- @return table|nil  { root = <string>, beans_dir = <string> }
function M.locate(path)
  local root = M.find_root(path)
  if not root then
    return nil
  end
  return { root = root, beans_dir = M.beans_dir(root) }
end

return M
