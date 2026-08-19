-- beans.schema — vocabulary discovery, mnemonics, prefetch and caching.
--
-- Vocabularies (status/type/priority values) are discovered at runtime by
-- parsing `beans update --help` (briefing §2.3), never hardcoded; the config
-- `fallback` table is used only when parsing yields nothing. Mnemonics for the
-- enum steps are computed from the discovered vocabulary. Reads are prefetched
-- and cached per project root.

local cli = require("beans.cli")

local M = {}

--- Static value hints (from Beans' config.go). A lookup miss is fine — hints
--- are cosmetic (briefing §2.3).
M.hints = {
  status = {
    ["in-progress"] = "Currently being worked on",
    ["todo"] = "Ready to be worked on",
    ["draft"] = "Needs refinement before it can be worked on",
    ["completed"] = "Finished successfully",
    ["scrapped"] = "Will not be done",
  },
  type = {
    ["milestone"] = "A target release or checkpoint",
    ["epic"] = "A thematic container for related work",
    ["bug"] = "Something that is broken and needs fixing",
    ["feature"] = "A user-facing capability or enhancement",
    ["task"] = "A concrete piece of work to complete",
  },
  priority = {
    ["critical"] = "Urgent, blocking work",
    ["high"] = "Important, should be done before normal work",
    ["normal"] = "Standard priority",
    ["low"] = "Less important, can be delayed",
    ["deferred"] = "Explicitly pushed back",
  },
}

--- Parse the values of one `--<field>` flag out of `beans update --help`.
--- Rule (§2.3): find the `--<field>` line, capture the first parenthesised
--- group, split on commas, trim, and discard any item containing whitespace
--- (this cleanly drops "or empty to clear").
--- @param help string  the full --help text
--- @param field string  e.g. "status"
--- @return string[]|nil  the values, or nil if not found
function M.parse_field(help, field)
  if not help or help == "" then
    return nil
  end
  for line in (help .. "\n"):gmatch("(.-)\n") do
    if line:match("%-%-" .. field .. "%f[%W]") then
      local group = line:match("%((.-)%)")
      if group then
        local values = {}
        for item in (group .. ","):gmatch("(.-),") do
          local trimmed = item:gsub("^%s+", ""):gsub("%s+$", "")
          -- Discard multi-word items like "or empty to clear".
          if trimmed ~= "" and not trimmed:match("%s") then
            table.insert(values, trimmed)
          end
        end
        if #values > 0 then
          return values
        end
      end
    end
  end
  return nil
end

--- Parse status/type/priority vocabularies from --help text.
--- @param help string
--- @return table { status = {...}|nil, type = {...}|nil, priority = {...}|nil }
function M.parse_vocab(help)
  return {
    status = M.parse_field(help, "status"),
    type = M.parse_field(help, "type"),
    priority = M.parse_field(help, "priority"),
  }
end

--- Resolve vocab, filling gaps from the fallback table.
--- @param parsed table  output of parse_vocab (any field may be nil)
--- @param fallback table  config.fallback
--- @return table  { status, type, priority } all non-nil
local function with_fallback(parsed, fallback)
  fallback = fallback or {}
  parsed = parsed or {}
  return {
    status = parsed.status or fallback.status,
    type = parsed.type or fallback.type,
    priority = parsed.priority or fallback.priority,
  }
end

--- Assign a unique single-character mnemonic to each value.
--- Strategy (§4.2): first letter → next unused letter in the word → digits 1..9.
--- @param values string[]  ordered list of values
--- @param overrides table|nil  value -> forced key
--- @return table  value -> mnemonic
function M.assign_mnemonics(values, overrides)
  overrides = overrides or {}
  local used = {}
  local result = {}

  -- Honour explicit overrides first.
  for _, v in ipairs(values) do
    local o = overrides[v]
    if o and not used[o] then
      result[v] = o
      used[o] = true
    end
  end

  -- First / next unused letter of the word.
  for _, v in ipairs(values) do
    if not result[v] then
      for c in v:lower():gmatch("%a") do
        if not used[c] then
          result[v] = c
          used[c] = true
          break
        end
      end
    end
  end

  -- Fall through to digits 1..9.
  for _, v in ipairs(values) do
    if not result[v] then
      for d = 1, 9 do
        local ds = tostring(d)
        if not used[ds] then
          result[v] = ds
          used[ds] = true
          break
        end
      end
    end
  end

  return result
end

----------------------------------------------------------------------
-- Prefetch and caching (per project root)
----------------------------------------------------------------------

local uv = vim.uv or vim.loop
local LIST_TTL_MS = 30 * 1000

M._vocab_cache = {} -- root -> vocab table (session-lived)
M._list_cache = {} -- root -> { data = <array>, at = <ms> }

--- Discover vocabularies for a project, caching per root for the session.
--- Falls back to config.fallback when the binary is missing or unparsable.
--- @param config table
--- @param ctx table  { root, beans_dir }
--- @param callback fun(vocab: table)
function M.get_vocab(config, ctx, callback)
  local root = ctx and ctx.root or "."
  if M._vocab_cache[root] then
    callback(M._vocab_cache[root])
    return
  end
  cli.run(config, { "update", "--help" }, {
    cwd = root,
    beans_path = ctx and ctx.beans_dir or nil,
  }, function(result)
    local parsed = result.ok and M.parse_vocab(result.stdout) or {}
    local vocab = with_fallback(parsed, config and config.fallback)
    M._vocab_cache[root] = vocab
    callback(vocab)
  end)
end

--- List beans (tag universe + candidates), cached per root with a short TTL.
--- @param config table
--- @param ctx table
--- @param callback fun(list: table|nil)
function M.get_list(config, ctx, callback)
  local root = ctx and ctx.root or "."
  local cached = M._list_cache[root]
  if cached and (uv.now() - cached.at) < LIST_TTL_MS then
    callback(cached.data)
    return
  end
  cli.run_json(config, { "list", "--json" }, {
    cwd = root,
    beans_path = ctx and ctx.beans_dir or nil,
  }, function(decoded)
    if decoded then
      M._list_cache[root] = { data = decoded, at = uv.now() }
    end
    callback(decoded)
  end)
end

--- Invalidate the list cache for a root (call on BufWritePost of any bean).
--- @param root string
function M.invalidate_list(root)
  M._list_cache[root] = nil
end

--- Fire both reads so steps 4/5 have data by the time they are reached.
--- @param config table
--- @param ctx table
function M.prefetch(config, ctx)
  M.get_vocab(config, ctx, function() end)
  M.get_list(config, ctx, function() end)
end

return M
