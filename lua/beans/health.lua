-- beans.health — `:checkhealth beans`.
--
-- Detection failures are the most likely support question, so this report is
-- built to be self-diagnosing (briefing §6). Milestone 04 extends it with
-- discovered vocabularies and cache state; this milestone covers the binary,
-- project root, bean directory, and whether the current buffer is recognised.

local M = {}

function M.check()
  local health = vim.health
  health.start("beans.nvim")

  local beans = require("beans")
  health.info(("beans.nvim version: %s"):format(beans.version or "unknown"))

  local config = beans.config or require("beans.config").merge()

  -- Binary + version.
  local exe = config.executable or "beans"
  if vim.fn.executable(exe) == 1 then
    local ver = vim.trim(vim.fn.system({ exe, "version" }))
    if vim.v.shell_error == 0 and ver ~= "" then
      health.ok(("beans binary found: %s"):format(ver))
    else
      health.ok(("beans binary found: %s"):format(exe))
    end
  else
    health.warn(("beans not found on PATH (executable = %q)"):format(exe), {
      "Install beans or set `executable` to an absolute path in setup().",
    })
  end

  -- Current buffer.
  local bufnr = vim.api.nvim_get_current_buf()
  local detect = require("beans.detect")
  local schema = require("beans.schema")
  local ctx = detect.detect(bufnr, config)
  if ctx then
    health.ok(("current buffer is a recognised bean: %s"):format(ctx.id or "<unknown id>"))
    if ctx.root then
      health.info(("project root: %s"):format(ctx.root))
      health.info(("bean directory: %s"):format(ctx.beans_dir))

      -- Discovered vocabularies + cache state.
      local vocab = schema._vocab_cache[ctx.root]
      if vocab then
        for _, f in ipairs({ "status", "type", "priority" }) do
          if vocab[f] then
            health.info(("vocab.%s: %s"):format(f, table.concat(vocab[f], ", ")))
          end
        end
      else
        health.info("vocabularies: not yet discovered (will prefetch on open)")
      end
      local list = schema._list_cache[ctx.root]
      health.info(("list cache: %s"):format(list and (#list.data .. " beans cached") or "empty"))
    else
      health.info("recognised by content (no project root on disk)")
    end
  else
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      health.info("current buffer has no file — not a bean")
    else
      local located = require("beans.project").locate(path)
      if not located then
        health.info(
          ("current buffer is not a bean: no .beans.yml/.beans found above %s"):format(path)
        )
      else
        health.info(
          ("current buffer is not a bean: file is not under %s and has no bean frontmatter"):format(
            located.beans_dir
          )
        )
      end
    end
  end
end

return M
