-- beans.wizard.steps.parent — single-select from a (long) candidate list.
--
-- Primary interaction is a normal-mode list (briefing §4.2, refined): j/k (and
-- <C-n>/<C-p>) move, <CR> selects the candidate under the cursor, `x`/the clear
-- entry removes an existing parent. Typing is an OPTIONAL filter reached with `/`
-- (an editable prompt line inside the wizard buffer — no blocking prompt, §11.0).
-- The step never seeds its query from stale buffer content: the query lives in
-- state, defaults to empty, and the list view is non-modifiable.

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
  -- cursor 0 == the "(clear parent)" entry; candidates are 1..#filtered.
  -- query is held in state (never read from the float buffer on entry), so the
  -- previous step's content can never leak into this step (bug: stale tags).
  state.parent = { cursor = 0, filtered = all, query = "" }
  local st = state.parent

  local function refilter()
    local q = st.query
    if q == "" then
      st.filtered = all
    else
      local displays, by_display = {}, {}
      for _, c in ipairs(all) do
        table.insert(displays, c.display)
        by_display[c.display] = c
      end
      st.filtered = {}
      for _, d in ipairs(vim.fn.matchfuzzy(displays, q)) do
        table.insert(st.filtered, by_display[d])
      end
    end
    if st.cursor > #st.filtered then
      st.cursor = #st.filtered
    end
    if st.cursor < 0 then
      st.cursor = 0
    end
  end

  local function apply()
    pcall(vim.cmd, "stopinsert")
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

  local bind_list, bind_filter

  -- List view (normal mode, non-modifiable): the primary interaction.
  local function draw_list()
    local title = "parent"
    if st.query ~= "" then
      title = title .. "  /" .. st.query
    end
    local options = { { label = "(clear parent)", current = (st.cursor == 0) } }
    for i, c in ipairs(st.filtered) do
      options[i + 1] = { label = c.display, current = (i == st.cursor) }
    end
    ui.render(state, {
      title = title,
      progress = wizard.progress(state),
      options = options,
      footer = "j/k move · <CR> select · / filter · x clear · <S-Tab> back · <Esc> finish",
    })
    -- Keep the window cursor on the highlighted option line.
    if ui.is_open(state) and state.ui.option_offset then
      pcall(
        vim.api.nvim_win_set_cursor,
        state.ui.win,
        { state.ui.option_offset + 1 + st.cursor, 0 }
      )
    end
  end

  --- Resolve the option under the window cursor (0 == clear, i == candidate i).
  local function cursor_option()
    if not (ui.is_open(state) and state.ui.option_offset) then
      return st.cursor
    end
    local row = vim.api.nvim_win_get_cursor(state.ui.win)[1]
    local c = row - state.ui.option_offset - 1
    if c < 0 then
      c = 0
    end
    if c > #st.filtered then
      c = #st.filtered
    end
    return c
  end

  local function move(delta)
    st.cursor = math.max(0, math.min(#st.filtered, st.cursor + delta))
    draw_list()
  end

  bind_list = function()
    wizard.clear_maps(state)
    wizard.map(state, "n", keys.prev or "<S-Tab>", function()
      state.parent = nil
      wizard.back(state)
    end)
    wizard.map(state, "n", keys.finish or { "<Esc>", "q" }, function()
      wizard.finish(state)
    end)
    wizard.map(state, "n", keys.abort or "<C-c>", function()
      wizard.finish(state)
    end)

    wizard.map(state, "n", keys.down or { "j", "<Down>", "<C-n>" }, function()
      move(1)
    end)
    wizard.map(state, "n", keys.up or { "k", "<Up>", "<C-p>" }, function()
      move(-1)
    end)
    wizard.map(state, "n", keys.select or "<CR>", function()
      st.cursor = cursor_option()
      apply()
    end)
    wizard.map(state, "n", keys.clear or "x", function()
      st.cursor = 0
      apply()
    end)
    wizard.map(state, "n", "/", function()
      bind_filter()
    end)

    draw_list()
  end

  -- Filter view (optional): an editable prompt line, live-narrowing the list.
  bind_filter = function()
    wizard.clear_maps(state)
    local function render_filter()
      local options = { { label = "(clear parent)", current = false } }
      for i, c in ipairs(st.filtered) do
        options[i + 1] = { label = c.display }
      end
      ui.render(state, {
        title = "parent · filter",
        progress = wizard.progress(state),
        prompt = st.query,
        options = options,
        footer = "type to filter · <CR>/<Esc> back to list",
      })
    end
    render_filter()
    if ui.is_open(state) then
      pcall(vim.api.nvim_win_set_cursor, state.ui.win, { 2, #st.query })
    end
    vim.cmd("startinsert!")

    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
      group = state._augroup,
      buffer = state.ui.buf,
      callback = function()
        st.query = vim.trim(vim.api.nvim_buf_get_lines(state.ui.buf, 1, 2, false)[1] or "")
        refilter()
        render_filter()
      end,
    })

    local function to_list()
      pcall(vim.cmd, "stopinsert")
      bind_list()
    end
    wizard.map(state, "i", keys.select or "<CR>", to_list)
    wizard.map(state, "i", "<Esc>", to_list)
  end

  -- Handlers exposed for deterministic layer-2 testing (the insert-mode filter
  -- prompt is the real-use surface for typing; primary selection is normal mode).
  st.select = apply
  st.move = move
  st.set_query = function(q)
    st.query = q or ""
    refilter()
    if ui.is_open(state) then
      draw_list()
    end
  end

  bind_list()
end

return M
