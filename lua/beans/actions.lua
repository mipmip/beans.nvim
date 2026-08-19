-- beans.actions — random-access entry points for `:Bean` / `:Bean <field>`.
--
-- When the target bean is open in a buffer we reuse the wizard's buffer-edit
-- code path (briefing §5.1); the `beans update` CLI is only a fallback for a
-- bean that is not currently open. Unlike the wizard, this path may use
-- vim.ui.select (it is outside the wizard and stubbable in tests).

local M = {}

M.FIELDS = { "status", "type", "priority", "tags", "parent" }

local function config()
  local ok, beans = pcall(require, "beans")
  return (ok and beans.config) or require("beans.config").merge()
end

--- Jump straight to one field on the current bean.
--- @param field string
function M.field(field)
  if not vim.tbl_contains(M.FIELDS, field) then
    vim.notify("beans.nvim: unknown field: " .. tostring(field), vim.log.levels.WARN)
    return
  end
  if vim.b.beans then
    -- Bean is open: buffer-edit path via the wizard, scoped to this one field.
    require("beans.wizard").start({ fields = { field } })
  else
    vim.notify("beans.nvim: not a bean buffer", vim.log.levels.WARN)
  end
end

--- Field menu → value picker (random access). Uses vim.ui.select (outside the
--- wizard), which is stubbable in tests.
function M.menu()
  if not vim.b.beans then
    vim.notify("beans.nvim: not a bean buffer", vim.log.levels.WARN)
    return
  end
  vim.ui.select(M.FIELDS, { prompt = "Beans: edit field" }, function(choice)
    if choice then
      M.field(choice)
    end
  end)
end

--- CLI fallback: update a bean that is NOT open in a buffer.
--- @param id string  bean id
--- @param flags string[]  e.g. { "--status", "todo" }
--- @param ctx table|nil  { root, beans_dir }
--- @param callback fun(ok: boolean, result: table)|nil
function M.cli_update(id, flags, ctx, callback)
  local cli = require("beans.cli")
  local args = { "update", id }
  vim.list_extend(args, flags)
  cli.run(config(), args, {
    cwd = ctx and ctx.root,
    beans_path = ctx and ctx.beans_dir,
  }, function(result)
    if callback then
      callback(result.ok, result)
    end
  end)
end

return M
