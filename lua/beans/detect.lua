-- beans.detect — decide whether a buffer is a bean, and expose the context.
--
-- Two independent checks (briefing §6), either one sufficient:
--   1. Path    — the file lives under the project's bean directory (incl. archive/).
--   2. Content — the first few lines carry `---`, a `# <id>` comment and a `title:`.
--
-- A positive match yields a context table { id, root, beans_dir, bufnr }. Nothing
-- is attached to non-bean buffers by this module.

local project = require("beans.project")

local M = {}

--- Extract the bean id from a filename of the form `<id>--<slug>.md`.
--- @param path string
--- @return string|nil
function M.id_from_filename(path)
  local name = vim.fs.basename(path or "")
  local id = name:match("^(.-)%-%-.+%.md$")
  if id and id ~= "" then
    return id
  end
  return nil
end

--- Inspect the first lines of a bean for the content signature.
--- Requires: line 1 is exactly `---`, and before the closing `---` there is a
--- `# <id>` comment and a `title:` key.
--- @param lines string[]  the first N lines of the buffer
--- @return string|nil id  the bean id from the `# <id>` comment, or nil
function M.content_id(lines)
  if not lines or lines[1] ~= "---" then
    return nil
  end

  local id, has_title = nil, false
  for i = 2, #lines do
    local line = lines[i]
    if line == "---" then
      break
    end
    local comment_id = line:match("^#%s+(%S+)%s*$")
    if comment_id then
      id = comment_id
    end
    if line:match("^%s*title:%s*%S") then
      has_title = true
    end
  end

  if id and has_title then
    return id
  end
  return nil
end

--- Is `path` located under `beans_dir` (including any `archive/` subdirectory)?
--- @param path string
--- @param beans_dir string
--- @return boolean
function M.is_under(path, beans_dir)
  if not path or not beans_dir then
    return false
  end
  local p = vim.fs.normalize(path)
  local d = vim.fs.normalize(beans_dir)
  return p == d or p:sub(1, #d + 1) == d .. "/"
end

--- Should this buffer name be ignored (config.detect.ignore patterns)?
--- @param path string
--- @param ignore string[]|nil
--- @return boolean
local function ignored(path, ignore)
  if not ignore then
    return false
  end
  for _, pat in ipairs(ignore) do
    if path:match(pat) then
      return true
    end
  end
  return false
end

--- Detect whether `bufnr` is a bean under `config`.
--- @param bufnr integer
--- @param config table  the resolved plugin config
--- @return table|nil context  { id, root, beans_dir, bufnr } or nil
function M.detect(bufnr, config)
  config = config or {}
  local detect_cfg = config.detect or {}
  if detect_cfg.by_path == nil then
    detect_cfg =
      vim.tbl_extend("keep", detect_cfg, { by_path = true, by_content = true, max_lines = 5 })
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return nil
  end
  path = vim.fs.normalize(path)

  if ignored(path, detect_cfg.ignore) then
    return nil
  end

  local located = project.locate(path)

  -- Path check.
  local by_path = false
  if detect_cfg.by_path ~= false and located and M.is_under(path, located.beans_dir) then
    by_path = true
  end

  -- Content check.
  local content_id = nil
  if detect_cfg.by_content ~= false then
    local n = detect_cfg.max_lines or 5
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, n, false)
    content_id = M.content_id(lines)
  end

  if not by_path and not content_id then
    return nil
  end

  local id = content_id or M.id_from_filename(path)
  local root = located and located.root or nil
  local beans_dir = located and located.beans_dir or nil

  return {
    id = id,
    root = root,
    beans_dir = beans_dir,
    bufnr = bufnr,
  }
end

----------------------------------------------------------------------
-- Auto-start heuristic (briefing §6.1)
----------------------------------------------------------------------

--- Convert broken-down UTC time to a true epoch, correcting for the local
--- timezone offset (os.time interprets its table as local wall-clock time).
--- @return integer
local function utc_to_epoch(y, mo, d, h, mi, s)
  local now = os.time()
  local offset = os.difftime(os.time(os.date("*t", now)), os.time(os.date("!*t", now)))
  return os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
    isdst = false,
  }) + offset
end

--- Parse `created_at` (ISO-8601 UTC) from frontmatter lines into an epoch.
--- @param lines string[]
--- @return integer|nil epoch
function M.parse_created_at(lines)
  for _, line in ipairs(lines or {}) do
    local y, mo, d, h, mi, s = line:match("^%s*created_at:%s*(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
    if y then
      return utc_to_epoch(y, mo, d, h, mi, s)
    end
  end
  return nil
end

--- Is the bean body (everything after the closing `---`) empty/whitespace-only?
--- @param lines string[]  the full buffer lines
--- @return boolean
function M.body_is_empty(lines)
  lines = lines or {}
  if lines[1] ~= "---" then
    return false
  end
  local close = nil
  for i = 2, #lines do
    if lines[i] == "---" then
      close = i
      break
    end
  end
  if not close then
    return false
  end
  for i = close + 1, #lines do
    if lines[i]:match("%S") then
      return false
    end
  end
  return true
end

--- Decide whether the wizard should auto-start for a freshly opened bean.
--- All of: recognised bean (caller's precondition) AND created_at within
--- `max_age_seconds` of now AND (if require_empty_body) an empty body.
--- @param lines string[]  full buffer lines
--- @param autostart table  config.wizard.autostart
--- @param now_epoch integer|nil  defaults to os.time()
--- @return boolean
function M.should_autostart(lines, autostart, now_epoch)
  autostart = autostart or {}
  if autostart.enabled == false then
    return false
  end
  now_epoch = now_epoch or os.time()

  local created = M.parse_created_at(lines)
  if not created then
    return false
  end
  local max_age = autostart.max_age_seconds or 30
  if (now_epoch - created) > max_age or (now_epoch - created) < -max_age then
    return false
  end

  if autostart.require_empty_body ~= false and not M.body_is_empty(lines) then
    return false
  end

  return true
end

return M
