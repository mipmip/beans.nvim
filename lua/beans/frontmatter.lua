-- beans.frontmatter — pure line-list parse/edit for bean YAML frontmatter.
--
-- Every function operates on a list of lines (an array of strings, no trailing
-- newlines) and returns a NEW list, leaving the input untouched. Nothing here
-- touches a buffer, so it is fully unit-testable; the caller applies a returned
-- list with a single `nvim_buf_set_lines` so each field change is one undo step.
--
-- Quoting and indentation are matched to what Beans (go-yaml v3) actually emits,
-- verified against the real CLI (beans-nvim-briefing.md §2.2, §5.2, §14.1):
--   * structural values (contain `:`/`#`, leading/trailing space) -> single quotes
--   * type-ambiguous values (yes/no/true/false/null, numeric) -> double quotes
--   * everything else -> plain
--   * `tags:` block sequence items are indented 4 spaces
--
-- The canonical field order is Beans', not ours, and is not configurable.

local M = {}

--- Canonical frontmatter key order (§2.2).
local ORDER = {
  "title",
  "status",
  "type",
  "priority",
  "tags",
  "created_at",
  "updated_at",
  "order",
  "parent",
  "blocking",
  "blocked_by",
}

local RANK = {}
for i, key in ipairs(ORDER) do
  RANK[key] = i
end

--- Default indentation for `tags:` block-sequence items, matching go-yaml v3.
local LIST_ITEM_INDENT = "    "

-- Values that YAML would resolve as a non-string type; Beans double-quotes these.
local AMBIGUOUS = {
  ["true"] = true,
  ["false"] = true,
  ["yes"] = true,
  ["no"] = true,
  ["on"] = true,
  ["off"] = true,
  ["y"] = true,
  ["n"] = true,
  ["null"] = true,
  ["~"] = true,
}

local function copy(lines)
  local out = {}
  for i = 1, #lines do
    out[i] = lines[i]
  end
  return out
end

local function is_numeric(v)
  -- integers, decimals, and simple scientific notation
  if v:match("^[%+%-]?%d+$") then
    return true
  end
  if v:match("^[%+%-]?%d*%.%d+$") or v:match("^[%+%-]?%d+%.%d*$") then
    return true
  end
  if v:match("^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+$") then
    return true
  end
  return false
end

-- Decide the quote style for a scalar value: nil (plain), "'" or '"'.
local function quote_style(v)
  if v == "" then
    return '"'
  end
  if AMBIGUOUS[v:lower()] or is_numeric(v) then
    return '"'
  end
  -- leading/trailing whitespace
  if v:match("^%s") or v:match("%s$") then
    return "'"
  end
  -- comment / mapping indicators
  if v:find("#", 1, true) or v:find(":", 1, true) then
    return "'"
  end
  -- a leading YAML indicator character forces quoting
  local first = v:sub(1, 1)
  if first:match("[%-%?%[%]{},&%*!|>'\"%%@`]") then
    return "'"
  end
  return nil
end

--- Render a scalar value the way Beans would serialize it.
--- @param v string
--- @return string
function M.render_value(v)
  local style = quote_style(v)
  if style == nil then
    return v
  elseif style == "'" then
    return "'" .. v:gsub("'", "''") .. "'"
  else
    return '"' .. v:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
  end
end

--- Locate the frontmatter block.
--- @param lines string[]
--- @return table|nil  { open = <idx of opening `---`>, close = <idx of closing `---`> }
function M.find_block(lines)
  if lines[1] ~= "---" then
    return nil
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      return { open = 1, close = i }
    end
  end
  return nil
end

-- List top-level (unindented) key lines within the block, in order.
local function block_keys(lines, block)
  local keys = {}
  for i = block.open + 1, block.close - 1 do
    local indent, key = lines[i]:match("^(%s*)([%w_]+):")
    if key and indent == "" then
      keys[#keys + 1] = { key = key, idx = i }
    end
  end
  return keys
end

local function find_key(lines, block, key)
  for _, k in ipairs(block_keys(lines, block)) do
    if k.key == key then
      return k.idx
    end
  end
  return nil
end

-- The absolute line index at which a currently-absent key should be inserted so
-- the result stays in canonical order.
local function insertion_index(lines, block, key)
  local rank = RANK[key]
  for _, k in ipairs(block_keys(lines, block)) do
    if RANK[k.key] and RANK[k.key] > rank then
      return k.idx
    end
  end
  -- No later-ranked key present: insert just before the closing fence.
  return block.close
end

-- Extent of a block-sequence value (the key line plus its indented item lines).
local function list_extent(lines, block, key_idx)
  local last = key_idx
  for i = key_idx + 1, block.close - 1 do
    if lines[i]:match("^%s") and lines[i] ~= "" then
      last = i
    else
      break
    end
  end
  return last
end

--- Set (or insert) a scalar key to `value`, with an optional trailing comment.
---
--- When `comment` is given it is appended as a YAML inline comment
--- (`key: value # comment`) AFTER the value is serialized/quoted — it is never
--- folded into the value, so value quoting is unaffected. The line is rebuilt
--- from scratch, so replacing a value that already carried a ` # …` comment
--- drops the old one (comments do not stack). With no comment the output is
--- unchanged from a plain scalar set (byte-identical to `beans update`).
--- @param lines string[]
--- @param key string
--- @param value string
--- @param comment string|nil  optional inline comment text (no leading `#`)
--- @return string[] new_lines, boolean ok  (ok=false when the input is not a bean)
function M.set_scalar(lines, key, value, comment)
  local out = copy(lines)
  local block = M.find_block(out)
  if not block then
    return out, false
  end
  local idx = find_key(out, block, key)
  local rendered = key .. ": " .. M.render_value(value)
  if comment ~= nil and comment ~= "" then
    -- Inline comments are single-line; collapse any newlines and trim the tail.
    local c = comment:gsub("[\r\n]+", " "):gsub("%s+$", "")
    if c ~= "" then
      rendered = rendered .. " # " .. c
    end
  end
  if idx then
    local indent = out[idx]:match("^(%s*)")
    out[idx] = indent .. rendered
  else
    table.insert(out, insertion_index(out, block, key), rendered)
  end
  return out, true
end

--- Remove a scalar key entirely (used to clear e.g. priority).
--- @param lines string[]
--- @param key string
--- @return string[] new_lines, boolean ok
function M.clear_scalar(lines, key)
  local out = copy(lines)
  local block = M.find_block(out)
  if not block then
    return out, false
  end
  local idx = find_key(out, block, key)
  if idx then
    table.remove(out, idx)
  end
  return out, true
end

--- Set (or insert) a block-sequence list key (e.g. tags). Empty `items` clears.
--- @param lines string[]
--- @param key string
--- @param items string[]
--- @return string[] new_lines, boolean ok
function M.set_list(lines, key, items)
  if not items or #items == 0 then
    return M.clear_list(lines, key)
  end
  local out = copy(lines)
  local block = M.find_block(out)
  if not block then
    return out, false
  end

  local idx = find_key(out, block, key)
  local item_indent = LIST_ITEM_INDENT
  local at
  if idx then
    -- Preserve the existing block's item indentation, then remove it.
    local last = list_extent(out, block, idx)
    for i = idx + 1, last do
      local ind = out[i]:match("^(%s*)%-")
      if ind then
        item_indent = ind
        break
      end
    end
    for _ = idx, last do
      table.remove(out, idx)
    end
    at = idx
  else
    at = insertion_index(out, block, key)
  end

  local rendered = { key .. ":" }
  for _, item in ipairs(items) do
    rendered[#rendered + 1] = item_indent .. "- " .. M.render_value(item)
  end
  for offset, line in ipairs(rendered) do
    table.insert(out, at + offset - 1, line)
  end
  return out, true
end

--- Remove a block-sequence list key and all its items.
--- @param lines string[]
--- @param key string
--- @return string[] new_lines, boolean ok
function M.clear_list(lines, key)
  local out = copy(lines)
  local block = M.find_block(out)
  if not block then
    return out, false
  end
  local idx = find_key(out, block, key)
  if idx then
    local last = list_extent(out, block, idx)
    for _ = idx, last do
      table.remove(out, idx)
    end
  end
  return out, true
end

return M
