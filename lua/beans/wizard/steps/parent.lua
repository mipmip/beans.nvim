-- beans.wizard.steps.parent — single-select from a (long) candidate list.
--
-- Type to filter (briefing §4.2): the candidate list is long, so mnemonics are
-- useless. An editable prompt line inside the wizard buffer (no blocking
-- prompts, §11.0) filters via vim.fn.matchfuzzy over "<id> <title>".

local ui = require("beans.wizard.ui")

local M = {}

local TYPE_ORDER = { milestone = 1, epic = 2, feature = 3, bug = 4, task = 5 }

--- Build the candidate list: filtered by configured types, self excluded.
local function candidates(state)
  local cfg = state.config
  local fcfg = (cfg.fields and cfg.fields.parent) or {}
  local types = fcfg.types -- nil => any type
  local allow = types and {} or nil
  if types then
    for _, t in ipairs(types) do
      allow[t] = true
    end
  end

  local self_id = state.ctx and state.ctx.id
  local out = {}
  for _, bean in ipairs(state.data.list or {}) do
    if bean.id ~= self_id and (not allow or allow[bean.type]) then
      table.insert(out, {
        id = bean.id,
        title = bean.title or "",
        type = bean.type or "",
        display = string.format("%s %s", bean.id, bean.title or ""),
      })
    end
  end

  local sort = fcfg.sort or "type"
  table.sort(out, function(a, b)
    if sort == "id" then
      return a.id < b.id
    elseif sort == "type" then
      local ta, tb = TYPE_ORDER[a.type] or 99, TYPE_ORDER[b.type] or 99
      if ta ~= tb then
        return ta < tb
      end
      return a.display < b.display
    end
    return a.display < b.display
  end)
  return out
end

function M.enter(wizard, state)
  local keys = state.config.wizard.keys or {}
  local all = candidates(state)
  -- Cursor 0 == the "(clear parent)" entry; candidates are 1..n.
  state.parent = { cursor = 0, filtered = all }

  local st = state.parent

  local function query()
    if not ui.is_open(state) then
      return ""
    end
    return vim.trim(vim.api.nvim_buf_get_lines(state.ui.buf, 1, 2, false)[1] or "")
  end

  local function draw()
    local options = { { label = "(clear parent)", current = (st.cursor == 0) } }
    for i, c in ipairs(st.filtered) do
      options[i + 1] = { label = c.display, current = (i == st.cursor) }
    end
    ui.render(state, {
      title = "parent",
      progress = wizard.progress(state),
      prompt = query(),
      options = options,
      footer = "type to filter · <C-n>/<C-p> move · <CR> select · <Esc> finish",
    })
  end

  local function refilter()
    local q = query()
    if q == "" then
      st.filtered = all
    else
      local displays = {}
      for _, c in ipairs(all) do
        table.insert(displays, c.display)
      end
      local matched = vim.fn.matchfuzzy(displays, q)
      local by_display = {}
      for _, c in ipairs(all) do
        by_display[c.display] = c
      end
      st.filtered = {}
      for _, d in ipairs(matched) do
        table.insert(st.filtered, by_display[d])
      end
    end
    if st.cursor > #st.filtered then
      st.cursor = #st.filtered
    end
    if st.cursor < 0 then
      st.cursor = 0
    end
    draw()
  end

  local function apply_selection()
    vim.cmd("stopinsert")
    if st.cursor == 0 then
      wizard.clear_scalar(state, "parent")
    else
      local c = st.filtered[st.cursor]
      if c then
        wizard.set_scalar(state, "parent", c.id)
      end
    end
    state.parent = nil
    wizard.advance(state)
  end

  local function move(delta)
    local lo = 0 -- 0 == the "(clear parent)" entry
    local hi = #st.filtered
    st.cursor = math.max(lo, math.min(hi, st.cursor + delta))
    draw()
  end

  -- Expose handlers so the interaction is drivable without a live input loop
  -- (layer-2 tests); the insert-mode prompt below is the real-use surface and is
  -- exercised end-to-end at layer 4.
  st.select = apply_selection
  st.move = move
  st.set_query = function(q)
    if ui.is_open(state) then
      vim.api.nvim_buf_set_lines(state.ui.buf, 1, 2, false, { q })
    end
    refilter()
  end

  draw()
  -- Land on the prompt line in insert mode so typing filters immediately.
  if ui.is_open(state) then
    pcall(vim.api.nvim_win_set_cursor, state.ui.win, { 2, 0 })
  end
  vim.cmd("startinsert!")

  -- Re-filter as the user types.
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    group = state._augroup,
    buffer = state.ui.buf,
    callback = function()
      refilter()
    end,
  })

  -- Insert-mode controls.
  wizard.map(state, "i", keys.select or "<CR>", apply_selection)
  wizard.map(state, "i", "<C-n>", function()
    move(1)
  end)
  wizard.map(state, "i", "<C-p>", function()
    move(-1)
  end)
  wizard.map(state, "i", "<Esc>", function()
    state.parent = nil
    wizard.finish(state)
  end)
  wizard.map(state, "i", keys.prev or "<S-Tab>", function()
    vim.cmd("stopinsert")
    state.parent = nil
    wizard.back(state)
  end)
end

return M
