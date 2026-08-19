-- beans.wizard.ui — the near-cursor float: window management, rendering, and
-- highlights. Rendering is data-driven: a step produces a `model` and this
-- module lays it out. Keys are wired by the wizard core on the float buffer, so
-- everything the user types goes through buffer-local keymaps (briefing §11.0).

local M = {}

local HL = {
  title = "BeansWizardTitle",
  key = "BeansWizardKey",
  current = "BeansWizardCurrent",
  active = "BeansWizardActive",
  hint = "BeansWizardHint",
  field_line = "BeansFieldLine",
  flash = "BeansFlash",
}

M.ns = vim.api.nvim_create_namespace("beans.wizard")
M.doc_ns = vim.api.nvim_create_namespace("beans.wizard.doc")

--- Define highlight groups, each linking to a standard group by default so any
--- colorscheme works untouched (briefing §7.4). Idempotent.
function M.setup_highlights()
  local links = {
    BeansWizardTitle = "Title",
    BeansWizardKey = "Special",
    BeansWizardCurrent = "CursorLine",
    BeansWizardActive = "DiagnosticOk",
    BeansWizardHint = "Comment",
    BeansFieldLine = "Visual",
    BeansFlash = "IncSearch",
  }
  for group, target in pairs(links) do
    if vim.fn.hlexists(group) == 0 or vim.api.nvim_get_hl(0, { name = group }).default then
      pcall(vim.api.nvim_set_hl, 0, group, { link = target, default = true })
    else
      pcall(vim.api.nvim_set_hl, 0, group, { link = target, default = true })
    end
  end
end

--- Open the float near the cursor and focus it.
--- @param state table  wizard state; window config read from state.config
--- @return table  { buf, win }
function M.open(state)
  M.setup_highlights()
  local wcfg = (state.config.wizard and state.config.wizard.window) or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "beans-wizard"

  local width = math.min(wcfg.max_width or 60, math.max(30, vim.o.columns - 4))
  local height = wcfg.max_height or 12
  local opts = {
    relative = (wcfg.position == "center") and "editor" or "cursor",
    width = width,
    height = height,
    style = "minimal",
    border = wcfg.border or "rounded",
    row = (wcfg.position == "center") and math.floor((vim.o.lines - height) / 2) or 1,
    col = (wcfg.position == "center") and math.floor((vim.o.columns - width) / 2) or 0,
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false

  state.ui = { buf = buf, win = win }
  return state.ui
end

--- Is the float currently open?
function M.is_open(state)
  return state.ui
    and state.ui.win
    and vim.api.nvim_win_is_valid(state.ui.win)
    and state.ui.buf
    and vim.api.nvim_buf_is_valid(state.ui.buf)
end

--- Close the float and clear document decorations.
function M.close(state)
  if state.ui and state.ui.win and vim.api.nvim_win_is_valid(state.ui.win) then
    pcall(vim.api.nvim_win_close, state.ui.win, true)
  end
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    pcall(vim.api.nvim_buf_clear_namespace, state.bufnr, M.doc_ns, 0, -1)
  end
  state.ui = nil
end

--- Resize the float to fit `nlines` (bounded by max_height).
local function fit_height(state, nlines)
  if not M.is_open(state) then
    return
  end
  local wcfg = (state.config.wizard and state.config.wizard.window) or {}
  local h = math.max(1, math.min(nlines, wcfg.max_height or 12))
  pcall(vim.api.nvim_win_set_height, state.ui.win, h)
end

--- Render a step model into the float.
--- model = {
---   title = string,           -- e.g. "type"
---   progress = string|nil,    -- e.g. "2/5"
---   prompt = string|nil,      -- editable prompt line (tags-new / parent-filter)
---   options = {               -- ordered
---     { label=string, mnemonic=string|nil, current=bool, active=bool, hint=string|nil }
---   },
---   footer = string|nil,
---   cursor_line = integer|nil, -- 1-based option index to place the cursor on
--- }
function M.render(state, model)
  if not M.is_open(state) then
    return
  end
  local buf = state.ui.buf
  local wcfg = (state.config.wizard and state.config.wizard.window) or {}

  local lines = {}
  local highlights = {} -- { line0, col0, col1, group }

  -- Title + progress.
  local title = model.title or ""
  if wcfg.progress ~= false and model.progress then
    title = string.format("%s · %s", model.progress, title)
  end
  table.insert(lines, title)
  table.insert(highlights, { 0, 0, -1, HL.title })

  -- Optional editable prompt line.
  local option_offset
  if model.prompt ~= nil then
    table.insert(lines, model.prompt)
    option_offset = #lines -- options start after the prompt
  else
    option_offset = #lines
  end

  -- Options.
  for i, opt in ipairs(model.options or {}) do
    local prefix = opt.mnemonic and (opt.mnemonic .. "  ") or "   "
    local marker = opt.active and "● " or "  "
    local text = prefix .. marker .. opt.label
    local hint = (wcfg and true) and opt.hint or nil
    if hint and hint ~= "" then
      text = text .. "   " .. hint
    end
    local lnum = #lines -- 0-based index of the line we are about to add
    table.insert(lines, text)

    if opt.mnemonic then
      table.insert(highlights, { lnum, 0, #opt.mnemonic, HL.key })
    end
    if opt.active then
      local lbl_start = #prefix + #marker
      table.insert(highlights, { lnum, lbl_start, lbl_start + #opt.label, HL.active })
    end
    if hint and hint ~= "" then
      local hstart = #text - #hint
      table.insert(highlights, { lnum, hstart, -1, HL.hint })
    end
    if opt.current then
      table.insert(highlights, { lnum, 0, -1, HL.current })
    end
    opt._line0 = lnum
    _ = i
  end

  -- Footer.
  if model.footer and wcfg.footer ~= false then
    table.insert(lines, "")
    table.insert(lines, model.footer)
    table.insert(highlights, { #lines - 1, 0, -1, HL.hint })
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- The prompt line must stay editable for insert-mode filtering; other steps
  -- lock the buffer.
  vim.bo[buf].modifiable = model.prompt ~= nil

  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  for _, h in ipairs(highlights) do
    pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, h[1], h[2], {
      end_col = h[3] == -1 and nil or h[3],
      end_row = h[3] == -1 and h[1] + 1 or nil,
      hl_group = h[4],
      hl_eol = h[3] == -1,
    })
  end

  fit_height(state, #lines)

  state.ui.option_offset = option_offset
  return option_offset
end

--- Move the float's cursor to option index `i` (1-based).
function M.set_cursor(state, i)
  if not M.is_open(state) or not state.ui.option_offset then
    return
  end
  local line = state.ui.option_offset + i
  pcall(vim.api.nvim_win_set_cursor, state.ui.win, { math.max(1, line), 0 })
end

--- Highlight the frontmatter field line in the document (briefing §4.1).
--- @param state table
--- @param lnum0 integer|nil  0-based line to highlight, or nil to clear
function M.highlight_field(state, lnum0)
  if not (state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr)) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.bufnr, M.doc_ns, 0, -1)
  if lnum0 == nil then
    return
  end
  pcall(vim.api.nvim_buf_set_extmark, state.bufnr, M.doc_ns, lnum0, 0, {
    line_hl_group = HL.field_line,
  })
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_set_cursor, state.win, { lnum0 + 1, 0 })
  end
end

--- Briefly flash a document line after a change lands (briefing §4.1).
function M.flash(state, lnum0)
  local fcfg = (state.config.wizard and state.config.wizard.flash) or {}
  if fcfg.enabled == false or lnum0 == nil then
    return
  end
  if not (state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr)) then
    return
  end
  local id = vim.api.nvim_buf_set_extmark(state.bufnr, M.doc_ns, lnum0, 0, {
    line_hl_group = HL.flash,
  })
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(state.bufnr) then
      pcall(vim.api.nvim_buf_del_extmark, state.bufnr, M.doc_ns, id)
    end
  end, fcfg.duration_ms or 250)
end

return M
