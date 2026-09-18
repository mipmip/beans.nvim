-- beans.wizard.steps.enum — status / type / priority.
--
-- Press-the-letter = select + confirm + auto-advance (one keystroke per field,
-- briefing §4.2). Mnemonics are computed from the discovered vocabulary, never
-- hardcoded.

local ui = require("beans.wizard.ui")
local schema = require("beans.schema")

local M = {}

--- The value currently set on the bean for `key`, or nil.
local function current_value(lines, key)
  for _, l in ipairs(lines) do
    local v = l:match("^%s*" .. key .. ":%s*(.*)$")
    if v then
      v = v:gsub("%s+$", ""):gsub("^['\"]", ""):gsub("['\"]$", "")
      if v ~= "" then
        return v
      end
    end
  end
  return nil
end

--- Resolve `fields.<field>.default` to an index in `options`.
---
--- The default is cursor placement only: it decides where the step opens, never
--- what the buffer says. Returns nil when nothing usable is configured.
---
--- A configured value that the vocabulary does not contain is reported once per
--- project and field, then ignored. The report is withheld unless Beans actually
--- reported that vocabulary: while the `fallback` table is standing in, a later
--- re-render may still find the value, and the warning would have to be
--- retracted.
--- @param state table
--- @param field string
--- @param values string[]  the vocabulary backing the option list
--- @param options table[]
--- @return integer|nil
local function default_index(state, field, values, options)
  local cfg = state.config
  local entry = cfg.fields and cfg.fields[field]
  local want = entry and entry.default
  if type(want) ~= "string" then
    return nil
  end

  for i, opt in ipairs(options) do
    if opt.value == want then
      return i
    end
  end

  local vocab = state.data.vocab
  local discovered = vocab and vocab.discovered and vocab.discovered[field]
  local root = state.ctx and state.ctx.root
  if discovered and root and schema.mark_default_warned(root, field) then
    require("beans.config").warn(
      cfg,
      string.format(
        'beans.nvim: fields.%s.default is "%s", which is not one of %s; ignoring it',
        field,
        want,
        table.concat(values, ", ")
      )
    )
  end
  return nil
end

function M.enter(wizard, state)
  local field = state.field
  local cfg = state.config
  local vocab = state.data.vocab or {}
  local values = vocab[field] or (cfg.fallback and cfg.fallback[field]) or {}

  -- Loading state: enum vocab should be available immediately, but guard anyway.
  if #values == 0 then
    ui.render(state, {
      title = field,
      progress = wizard.progress(state),
      options = { { label = "loading…" } },
      footer = "<Esc> finish",
    })
    return
  end

  local overrides = (cfg.wizard.mnemonics or {})[field] or {}
  local mnemonics = schema.assign_mnemonics(values, overrides)

  local allow_clear = field == "priority"
    and cfg.fields
    and cfg.fields.priority
    and cfg.fields.priority.allow_clear

  local lines = wizard.get_lines(state)
  local current = current_value(lines, field)

  -- Build the ordered option list.
  local options = {}
  for i, v in ipairs(values) do
    options[i] = {
      value = v,
      label = v,
      mnemonic = mnemonics[v],
      active = (v == current),
      hint = cfg.wizard.hints ~= false and (schema.hints[field] or {})[v] or nil,
    }
  end
  local clear_key = cfg.wizard.keys and cfg.wizard.keys.clear or "x"
  if allow_clear then
    table.insert(options, { value = nil, clear = true, label = "(clear)", mnemonic = clear_key })
  end

  -- Cursor starts on the currently-set value; failing that, on the configured
  -- default when the field is unset; failing that, on the first option.
  --
  -- The `current == nil` test is deliberate and is not the same as "no option is
  -- active". A bean carrying a value the vocabulary does not know (a hand-written
  -- `priority: urgent`) marks no option active but is still set, and moving the
  -- cursor to the default there would hide the discrepancy.
  state.cursor = 1
  local active_index
  for i, opt in ipairs(options) do
    if opt.active then
      active_index = i
      break
    end
  end
  if active_index then
    state.cursor = active_index
  elseif current == nil then
    state.cursor = default_index(state, field, values, options) or 1
  end

  local function draw()
    for i, opt in ipairs(options) do
      opt.current = (i == state.cursor)
    end
    ui.render(state, {
      title = field,
      progress = wizard.progress(state),
      options = options,
      footer = "letter select · <Tab> keep · <S-Tab> back · <Esc> finish",
    })
    ui.set_cursor(state, state.cursor)
  end

  local function choose(opt)
    if opt.clear then
      wizard.clear_scalar(state, field)
    else
      wizard.set_scalar(state, field, opt.value)
    end
    wizard.advance(state)
  end

  draw()

  local keys = cfg.wizard.keys or {}

  -- Navigation (bound first so a mnemonic can override on collision).
  wizard.map(state, "n", keys.down or { "j", "<Down>" }, function()
    state.cursor = math.min(#options, state.cursor + 1)
    draw()
  end)
  wizard.map(state, "n", keys.up or { "k", "<Up>" }, function()
    state.cursor = math.max(1, state.cursor - 1)
    draw()
  end)

  -- Select the highlighted option / accept current / clear.
  wizard.map(state, "n", keys.select or "<CR>", function()
    choose(options[state.cursor])
  end)
  wizard.map(state, "n", keys.next or "<Tab>", function()
    wizard.advance(state) -- accept current value unchanged
  end)
  if allow_clear then
    wizard.map(state, "n", clear_key, function()
      wizard.clear_scalar(state, field)
      wizard.advance(state)
    end)
  end

  -- Mnemonics: the keypress is both selection and confirmation.
  for _, opt in ipairs(options) do
    if opt.mnemonic and not opt.clear then
      wizard.map(state, "n", opt.mnemonic, function()
        choose(opt)
      end)
    end
  end
end

return M
