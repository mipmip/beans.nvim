-- beans.wizard — the wizard state machine.
--
-- Drives the configured `fields` order, applies each pick as a direct buffer
-- edit through frontmatter.lua (one nvim_buf_set_lines per field == one undo
-- step, briefing §4.4/§5.2), and never uses a blocking prompt anywhere
-- (§11.0) — all input is via buffer-local keymaps on the float buffer.

local ui = require("beans.wizard.ui")
local frontmatter = require("beans.frontmatter")

local M = {}

M._state = nil

local STEP_MODULES = {
  status = "beans.wizard.steps.enum",
  type = "beans.wizard.steps.enum",
  priority = "beans.wizard.steps.enum",
  tags = "beans.wizard.steps.tags",
  parent = "beans.wizard.steps.parent",
}

----------------------------------------------------------------------
-- Small helpers
----------------------------------------------------------------------

local function config()
  local ok, beans = pcall(require, "beans")
  return (ok and beans.config) or require("beans.config").merge()
end

local function lines_equal(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

--- Force an undo boundary so the next buffer edit is its own undo step.
local function undo_break(buf)
  local ul = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = ul
end

function M.get_lines(state)
  return vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false)
end

--- Replace the buffer with `new_lines` as a single undo step, unless unchanged.
--- @return boolean changed
local function commit(state, new_lines)
  local cur = M.get_lines(state)
  if lines_equal(cur, new_lines) then
    return false
  end
  undo_break(state.bufnr)
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, new_lines)
  return true
end

local function mark_changed(state, field)
  for _, f in ipairs(state.changed) do
    if f == field then
      return
    end
  end
  table.insert(state.changed, field)
end

--- Locate the 0-based document line of a frontmatter key, for cursor/flash.
local function field_line0(state, key)
  local lines = M.get_lines(state)
  local block = frontmatter.find_block(lines)
  if not block then
    return nil
  end
  for i = block.open + 1, block.close - 1 do
    if lines[i]:match("^%s*" .. key .. ":") then
      return i - 1
    end
  end
  return nil
end

----------------------------------------------------------------------
-- Apply operations (called by steps)
----------------------------------------------------------------------

function M.set_scalar(state, key, value)
  local new = frontmatter.set_scalar(M.get_lines(state), key, value)
  if new and commit(state, new) then
    mark_changed(state, key)
    ui.flash(state, field_line0(state, key))
  end
end

function M.clear_scalar(state, key)
  local new = frontmatter.clear_scalar(M.get_lines(state), key)
  if new and commit(state, new) then
    mark_changed(state, key)
  end
end

function M.set_list(state, key, items)
  local new
  if not items or #items == 0 then
    new = frontmatter.clear_list(M.get_lines(state), key)
  else
    new = frontmatter.set_list(M.get_lines(state), key, items)
  end
  if new and commit(state, new) then
    mark_changed(state, key)
    ui.flash(state, field_line0(state, key))
  end
end

----------------------------------------------------------------------
-- Keymaps on the float buffer
----------------------------------------------------------------------

--- Bind a buffer-local map on the float, recording it so it can be cleared on
--- step change. `lhs` may be a string or a list of strings; false is ignored.
function M.map(state, mode, lhs, fn)
  if lhs == nil or lhs == false then
    return
  end
  local list = type(lhs) == "table" and lhs or { lhs }
  for _, key in ipairs(list) do
    vim.keymap.set(mode, key, fn, { buffer = state.ui.buf, nowait = true, silent = true })
    table.insert(state._maps, { mode = mode, lhs = key })
  end
end

function M.clear_maps(state)
  for _, m in ipairs(state._maps) do
    pcall(vim.keymap.del, m.mode, m.lhs, { buffer = state.ui.buf })
  end
  state._maps = {}
  -- Clear any step-registered buffer autocmds (e.g. the parent filter).
  if state._augroup and ui.is_open(state) then
    pcall(vim.api.nvim_clear_autocmds, { group = state._augroup, buffer = state.ui.buf })
  end
end

--- Bind the keys common to every step (§4.3): back, finish, abort.
local function bind_universal(state)
  local keys = (state.config.wizard and state.config.wizard.keys) or {}
  M.map(state, "n", keys.prev or "<S-Tab>", function()
    M.back(state)
  end)
  M.map(state, "n", keys.finish or { "<Esc>", "q" }, function()
    M.finish(state)
  end)
  M.map(state, "n", keys.abort or "<C-c>", function()
    M.finish(state)
  end)
end

----------------------------------------------------------------------
-- Step navigation
----------------------------------------------------------------------

function M.goto_step(state, index)
  if index < 1 then
    index = 1
  end
  if index > #state.fields then
    return M.finish(state)
  end
  state.index = index
  state.field = state.fields[index]

  M.clear_maps(state)
  bind_universal(state)

  ui.highlight_field(state, field_line0(state, state.field))

  local mod = require(STEP_MODULES[state.field])
  mod.enter(M, state)
end

function M.advance(state)
  M.goto_step(state, state.index + 1)
end

function M.back(state)
  M.goto_step(state, state.index - 1)
end

function M.progress(state)
  return string.format("%d/%d", state.index, #state.fields)
end

----------------------------------------------------------------------
-- Finish
----------------------------------------------------------------------

function M.finish(state)
  if M._state ~= state then
    return
  end
  M._state = nil

  -- Leave insert mode if a prompt step was active.
  pcall(vim.cmd, "stopinsert")

  ui.close(state)

  local fin = (state.config.wizard and state.config.wizard.finish) or {}
  local mode = fin.cursor or "body_end"

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_set_current_win, state.win)
  end

  if mode ~= "keep" then
    local lines = M.get_lines(state)
    local block = frontmatter.find_block(lines)
    if block then
      -- Ensure there is at least one body line to land on.
      if #lines <= block.close then
        vim.api.nvim_buf_set_lines(state.bufnr, block.close, block.close, false, { "" })
        lines = M.get_lines(state)
      end
      local body_start = block.close + 1
      local target = (mode == "body_start") and body_start or #lines
      target = math.max(body_start, math.min(target, #lines))
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        pcall(vim.api.nvim_win_set_cursor, state.win, { target, 0 })
      end
    end
  end

  if fin.insert ~= false then
    -- Direct call so insert mode is active as soon as control returns to the
    -- input loop (reliable under both interactive use and headless tests).
    vim.cmd("startinsert!")
  end

  local hooks = state.config.hooks or {}
  if type(hooks.on_finish) == "function" then
    pcall(hooks.on_finish, state.ctx, state.changed)
  end
end

----------------------------------------------------------------------
-- Entry
----------------------------------------------------------------------

--- Start the wizard on the current bean buffer.
--- @param opts table|nil  { auto = bool }
function M.start(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local ctx = vim.b[bufnr].beans
  if not ctx then
    vim.notify("beans.nvim: not a bean buffer", vim.log.levels.WARN)
    return
  end

  -- Only one wizard at a time.
  if M._state then
    M.finish(M._state)
  end

  local cfg = config()
  local fields =
    vim.deepcopy((cfg.wizard and cfg.wizard.fields) or { "status", "type", "priority" })

  local state = {
    bufnr = bufnr,
    win = vim.api.nvim_get_current_win(),
    ctx = ctx,
    config = cfg,
    fields = fields,
    index = 0,
    picks = {},
    changed = {},
    original = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    _maps = {},
    _augroup = vim.api.nvim_create_augroup("beans.wizard.buf", { clear = true }),
    auto = opts.auto or false,
    data = {},
  }
  M._state = state

  ui.open(state)

  -- Prefetch data for the tags/parent steps; steps render a loading state until
  -- it lands and re-render via M.refresh (schema caches per root).
  local schema = require("beans.schema")
  if ctx.root then
    schema.get_vocab(cfg, ctx, function(vocab)
      state.data.vocab = vocab
      M.refresh(state)
    end)
    schema.get_list(cfg, ctx, function(list)
      state.data.list = list
      M.refresh(state)
    end)
  else
    state.data.vocab = require("beans.schema").parse_vocab("")
  end

  M.goto_step(state, 1)
end

--- Re-render the current step (e.g. when prefetch data arrives).
function M.refresh(state)
  if M._state ~= state or not ui.is_open(state) or not state.field then
    return
  end
  local mod = require(STEP_MODULES[state.field])
  M.clear_maps(state)
  bind_universal(state)
  mod.enter(M, state)
end

return M
