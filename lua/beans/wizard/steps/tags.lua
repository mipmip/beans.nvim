-- beans.wizard.steps.tags — multi-select over the project tag universe.
--
-- Accumulate then confirm (briefing §4.2): toggle checkboxes, add a new tag via
-- an editable prompt line INSIDE the wizard buffer (no blocking prompts, §11.0),
-- then <CR>/<Tab> to confirm and advance.

local ui = require("beans.wizard.ui")

local M = {}

--- Beans' tag rules: lowercase, `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`.
function M.valid_tag(tag)
  return vim.fn.match(tag, [[\v^[a-z][a-z0-9]*(-[a-z0-9]+)*$]]) == 0
end

--- Current tags set on the bean (block-sequence form).
local function current_tags(lines)
  local out, in_block = {}, false
  for _, l in ipairs(lines) do
    if l:match("^%s*tags:%s*$") then
      in_block = true
    elseif in_block then
      local item = l:match("^%s*-%s+(.+)%s*$")
      if item then
        table.insert(out, (item:gsub("%s+$", "")))
      else
        in_block = false
      end
    end
  end
  return out
end

--- The union of every tag seen across the project (from `beans list --json`).
local function tag_universe(list)
  local seen, out = {}, {}
  for _, bean in ipairs(list or {}) do
    for _, t in ipairs(bean.tags or {}) do
      if not seen[t] then
        seen[t] = true
        table.insert(out, t)
      end
    end
  end
  table.sort(out)
  return out
end

function M.enter(wizard, state)
  local cfg = state.config
  local keys = cfg.wizard.keys or {}
  local lines = wizard.get_lines(state)

  -- Build the item list once per activation, preserving check state across the
  -- new-tag prompt via state.tags.
  if not state.tags then
    local checked = {}
    for _, t in ipairs(current_tags(lines)) do
      checked[t] = true
    end
    local items = {}
    local seen = {}
    local function add(tag)
      if not seen[tag] then
        seen[tag] = true
        table.insert(items, { tag = tag, checked = checked[tag] or false })
      end
    end
    for _, t in ipairs(current_tags(lines)) do
      add(t)
    end
    for _, t in ipairs(tag_universe(state.data.list)) do
      add(t)
    end
    state.tags = { items = items, cursor = 1, message = nil }
  end

  local st = state.tags

  local function selected()
    local out = {}
    for _, it in ipairs(st.items) do
      if it.checked then
        table.insert(out, it.tag)
      end
    end
    return out
  end

  local function confirm()
    wizard.set_list(state, "tags", selected())
    state.tags = nil
    wizard.advance(state)
  end

  local bind_list, bind_prompt

  local function draw_list()
    local options = {}
    if #st.items == 0 then
      options = { { label = state.data.list and "no tags yet — press n to add" or "loading…" } }
    else
      for i, it in ipairs(st.items) do
        options[i] = {
          label = string.format("[%s] %s", it.checked and "x" or " ", it.tag),
          current = (i == st.cursor),
        }
      end
    end
    local footer = "<Space> toggle · n new · <CR>/<Tab> confirm · <S-Tab> back · <Esc> finish"
    if st.message then
      footer = st.message .. "  |  " .. footer
    end
    ui.render(state, {
      title = "tags",
      progress = wizard.progress(state),
      options = options,
      footer = footer,
    })
    ui.set_cursor(state, st.cursor)
  end

  bind_list = function()
    wizard.clear_maps(state)
    -- universal keys (back/finish/abort) rebound by the wizard on refresh; here
    -- we re-bind them too since we cleared.
    wizard.map(state, "n", keys.prev or "<S-Tab>", function()
      state.tags = nil
      wizard.back(state)
    end)
    wizard.map(state, "n", keys.finish or { "<Esc>", "q" }, function()
      wizard.finish(state)
    end)
    wizard.map(state, "n", keys.abort or "<C-c>", function()
      wizard.finish(state)
    end)

    wizard.map(state, "n", keys.down or { "j", "<Down>" }, function()
      st.cursor = math.min(math.max(#st.items, 1), st.cursor + 1)
      draw_list()
    end)
    wizard.map(state, "n", keys.up or { "k", "<Up>" }, function()
      st.cursor = math.max(1, st.cursor - 1)
      draw_list()
    end)
    wizard.map(state, "n", keys.toggle or "<Space>", function()
      local it = st.items[st.cursor]
      if it then
        it.checked = not it.checked
        draw_list()
      end
    end)
    wizard.map(state, "n", keys.new or "n", function()
      bind_prompt()
    end)
    wizard.map(state, "n", keys.select or "<CR>", confirm)
    wizard.map(state, "n", keys.next or "<Tab>", confirm)
    st.message = nil
    draw_list()
  end

  bind_prompt = function()
    wizard.clear_maps(state)
    ui.render(state, {
      title = "tags · new",
      progress = wizard.progress(state),
      prompt = "",
      options = {},
      footer = "type a tag · <CR> add · <Esc> cancel",
    })
    -- Cursor onto the prompt line (line 2, after the title) and insert.
    if ui.is_open(state) then
      pcall(vim.api.nvim_win_set_cursor, state.ui.win, { 2, 0 })
    end
    vim.cmd("startinsert!")

    local function submit()
      local text = vim.api.nvim_buf_get_lines(state.ui.buf, 1, 2, false)[1] or ""
      text = vim.trim(text)
      vim.cmd("stopinsert")
      if cfg.fields and cfg.fields.tags and cfg.fields.tags.normalize then
        text = text:lower()
      end
      if text == "" then
        bind_list()
        return
      end
      if
        (cfg.fields and cfg.fields.tags and cfg.fields.tags.validate) and not M.valid_tag(text)
      then
        st.message = "invalid tag: " .. text
        bind_list()
        return
      end
      -- Add (or check an existing) tag.
      local found = false
      for _, it in ipairs(st.items) do
        if it.tag == text then
          it.checked = true
          found = true
          break
        end
      end
      if not found then
        table.insert(st.items, 1, { tag = text, checked = true })
      end
      st.cursor = 1
      bind_list()
    end

    wizard.map(state, "i", keys.select or "<CR>", submit)
    wizard.map(state, "i", "<Esc>", function()
      vim.cmd("stopinsert")
      bind_list()
    end)
  end

  bind_list()
end

return M
