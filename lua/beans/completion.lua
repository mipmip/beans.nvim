-- beans.completion — insert-mode completion (opt-in).
--
-- A zero-dependency omnifunc is the baseline: it completes ONLY when the cursor
-- is inside the frontmatter block, after a known key (status/type/priority/
-- parent) or on a tags: list item. Outside those conditions it contributes
-- nothing, leaving the user's normal completion untouched (briefing §8).
--
-- Optional blink.cmp / nvim-cmp sources sit behind config flags (default off),
-- both lazily required so neither becomes a hard dependency. This module adds NO
-- insert-mode <Tab>/<CR> mappings.

local schema = require("beans.schema")

local M = {}

local ENUM_FIELDS = { status = true, type = true, priority = true }

-- Field detected during the findstart==1 call, reused for findstart==0.
M._ctx_field = nil

local function get_config()
  local ok, beans = pcall(require, "beans")
  return (ok and beans.config) or require("beans.config").merge()
end

--- Frontmatter bounds for a line list; returns close_row (1-based) or nil.
local function frontmatter_close(lines)
  if lines[1] ~= "---" then
    return nil
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      return i
    end
  end
  return nil
end

--- Is `row` (1-based) inside the frontmatter block?
local function in_frontmatter(lines, row)
  local close = frontmatter_close(lines)
  return close ~= nil and row >= 2 and row < close
end

--- Nearest preceding `key:` for a tags list item; used to confirm the block.
local function enclosing_key(lines, row)
  for i = row - 1, 2, -1 do
    local key = lines[i]:match("^%s*([%w_%-]+):")
    if key then
      return key
    end
  end
  return nil
end

--- Determine the completion context at the cursor.
--- @return string|nil field, integer|nil start_col (0-based byte)
local function detect_context(bufnr, row, col, line)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if not in_frontmatter(lines, row) then
    return nil
  end

  local before = line:sub(1, col)

  -- key: value lines (status/type/priority/parent).
  local key, after = before:match("^%s*([%w_]+):%s*(.*)$")
  if key and (ENUM_FIELDS[key] or key == "parent") then
    return key, #before - #after
  end

  -- tags: block list item ("- <partial>") whose enclosing key is tags.
  local item = before:match("^%s*%-%s*(.*)$")
  if item and enclosing_key(lines, row) == "tags" then
    return "tags", #before - #item
  end

  return nil
end

--- Candidate values (list of { word, menu }) for a field.
local function candidates(field, ctx, config)
  local root = (ctx and ctx.root) or "."
  local out = {}

  if ENUM_FIELDS[field] then
    local vocab = schema._vocab_cache[root] or {}
    local values = vocab[field] or (config.fallback and config.fallback[field]) or {}
    for _, v in ipairs(values) do
      table.insert(out, { word = v, menu = (schema.hints[field] or {})[v] })
    end
  elseif field == "tags" then
    local list = (schema._list_cache[root] or {}).data or {}
    local seen = {}
    for _, bean in ipairs(list) do
      for _, t in ipairs(bean.tags or {}) do
        if not seen[t] then
          seen[t] = true
          table.insert(out, { word = t })
        end
      end
    end
    table.sort(out, function(a, b)
      return a.word < b.word
    end)
  elseif field == "parent" then
    local list = (schema._list_cache[root] or {}).data or {}
    local self_id = ctx and ctx.id
    for _, bean in ipairs(list) do
      if bean.id ~= self_id then
        table.insert(out, { word = bean.id, menu = bean.title })
      end
    end
  end

  return out
end

--- The buffer-local omnifunc. Synchronous; reads only from schema caches.
--- @param findstart integer
--- @param base string
function M.omnifunc(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local line = vim.api.nvim_get_current_line()

  if findstart == 1 then
    local field, start_col = detect_context(bufnr, row, col, line)
    M._ctx_field = field
    if not field then
      return -3 -- cancel silently, leave normal completion alone
    end
    return start_col
  end

  local field = M._ctx_field
  if not field then
    return {}
  end

  local ctx = vim.b[bufnr].beans
  local config = get_config()
  local items = candidates(field, ctx, config)

  local needle = (base or ""):lower()
  local matches = {}
  for _, item in ipairs(items) do
    if needle == "" or vim.startswith(item.word:lower(), needle) then
      table.insert(matches, { word = item.word, menu = item.menu })
    end
  end
  return matches
end

--- Set the buffer-local omnifunc in a bean buffer, if enabled. Called from the
--- plugin's buffer attach. Returns the omnifunc rhs used.
--- @param bufnr integer
--- @return string|nil rhs
function M.setup_buffer(bufnr)
  local config = get_config()
  if not (config.completion and config.completion.omnifunc) then
    return nil
  end
  local rhs = "v:lua.require'beans.completion'.omnifunc"
  vim.bo[bufnr].omnifunc = rhs
  return rhs
end

--- Register optional blink.cmp / nvim-cmp sources, behind config flags. Both
--- default off and are lazily required; an absent plugin causes no error.
--- @param config table
function M.register_sources(config)
  config = config or get_config()
  local comp = config.completion or {}

  if comp.blink then
    pcall(function()
      local blink = require("blink.cmp")
      if blink and type(blink.add_source_provider) == "function" then
        blink.add_source_provider("beans", { module = "beans.completion.blink" })
      end
    end)
  end

  if comp.cmp then
    pcall(function()
      local cmp = require("cmp")
      if cmp and type(cmp.register_source) == "function" then
        cmp.register_source("beans", {
          complete = function(_, callback)
            callback({ items = {} })
          end,
        })
      end
    end)
  end
end

return M
