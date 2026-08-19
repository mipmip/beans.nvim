-- beans.nvim — a Neovim companion for the Beans flat-file issue tracker.
--
-- Public entry point: setup, detection autocmds, and buffer attachment.
-- `setup()` must never error, even when the `beans` binary is missing from
-- $PATH (it degrades to a health-check concern). Non-bean buffers get zero
-- footprint: no keymaps, autocmds-with-effects, commands, or popups.

local M = {}

local AUGROUP = "beans.nvim"

--- Call `mod.fn(...)` if it exists; silently no-op otherwise. Lets detection
--- wire keymaps and autostart to the wizard/actions before those milestones
--- land, without erroring or emitting noise.
local function dispatch(mod, fn, ...)
  local ok, m = pcall(require, mod)
  if ok and type(m) == "table" and type(m[fn]) == "function" then
    return m[fn](...)
  end
end

--- Attach buffer-local keymaps for a bean buffer, driven by config.keymaps.
--- @param bufnr integer
--- @param config table
local function attach_keymaps(bufnr, config)
  local km = config.keymaps
  if not km or km.enabled == false then
    return
  end
  local function map(lhs, rhs, desc)
    if lhs and lhs ~= false then
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
  end
  map(km.wizard, function()
    dispatch("beans.wizard", "start")
  end, "Beans: start wizard")
  map(km.menu, function()
    dispatch("beans.actions", "menu")
  end, "Beans: field menu")
  for _, field in ipairs({ "status", "type", "priority", "tags", "parent" }) do
    local lhs = km.fields and km.fields[field]
    map(lhs, function()
      dispatch("beans.actions", "field", field)
    end, "Beans: " .. field)
  end
end

--- Attach the plugin to a recognised bean buffer.
--- @param ctx table  { id, root, beans_dir, bufnr }
function M.attach(ctx)
  local bufnr = ctx.bufnr
  vim.b[bufnr].beans = ctx

  -- Prefetch reads so the tags/parent steps have data by the time they render.
  if ctx.root then
    dispatch("beans.schema", "prefetch", M.config, ctx)
  end

  attach_keymaps(bufnr, M.config)

  -- on_attach hook.
  local hooks = M.config.hooks or {}
  if type(hooks.on_attach) == "function" then
    pcall(hooks.on_attach, ctx)
  end

  -- Auto-start heuristic: only when this looks freshly created by the TUI.
  local detect = require("beans.detect")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if detect.should_autostart(lines, (M.config.wizard or {}).autostart) then
    dispatch("beans.wizard", "start", { auto = true })
  end
end

--- Run detection on a buffer and attach if it is a bean.
--- @param bufnr integer
function M.on_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local detect = require("beans.detect")
  local ctx = detect.detect(bufnr, M.config)
  if ctx then
    M.attach(ctx)
  end
end

--- Create the detection autocmds (idempotent — safe to call again on re-setup).
local function create_autocmds()
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(args)
      M.on_buffer(args.buf)
    end,
  })

  -- Invalidate the per-root list cache when any bean is saved.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(args)
      local ctx = vim.b[args.buf].beans
      if ctx and ctx.root then
        dispatch("beans.schema", "invalidate_list", ctx.root)
      end
    end,
  })
end

--- Merge user options over defaults, store the resolved config, and wire up
--- detection.
--- @param opts table|nil user configuration (see beans-nvim-briefing.md §7.3)
function M.setup(opts)
  local config = require("beans.config")
  M.config = config.merge(opts)

  create_autocmds()

  vim.api.nvim_create_user_command("BeanWizard", function()
    require("beans.wizard").start()
  end, { desc = "Start the beans wizard" })

  -- Handle buffers already loaded when setup() runs (e.g. lazy-load).
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "markdown" then
      M.on_buffer(bufnr)
    end
  end

  return M.config
end

return M
