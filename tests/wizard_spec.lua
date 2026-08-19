-- wizard_spec.lua — layer-2 in-process wizard specs (Milestone 03).
--
-- Drives the real wizard against a real buffer. Because the wizard uses no
-- blocking prompts (§11.0), nvim_feedkeys(keys, "x") executes synchronously and
-- assertions can run immediately after.

local wizard = require("beans.wizard")
local config = require("beans.config")
local schema = require("beans.schema")

local ROOT = "/tmp/beans-wizard-spec"

local CANNED_LIST = {
  { id = "beans-m1", title = "Milestone one", type = "milestone", tags = { "core" } },
  { id = "beans-e1", title = "Epic one", type = "epic", tags = { "core", "ui" } },
  { id = "beans-self", title = "This bean", type = "feature", tags = {} },
}

local function feed(keys)
  local t = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(t, "x", false)
end

local buf_counter = 0

--- Create a bean buffer, make it current, seed caches, and configure the plugin.
local function open_bean(lines, opts)
  opts = opts or {}
  buf_counter = buf_counter + 1
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, ROOT .. "/.beans/beans-self-" .. buf_counter .. "--x.md")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)

  local cfg = config.merge(opts.config)
  local beans = require("beans")
  beans.config = cfg

  local ctx = { id = "beans-self", root = ROOT, beans_dir = ROOT .. "/.beans", bufnr = buf }
  vim.b[buf].beans = ctx

  -- Seed caches so data is available synchronously.
  schema._vocab_cache[ROOT] = {
    status = cfg.fallback.status,
    type = cfg.fallback.type,
    priority = cfg.fallback.priority,
  }
  schema._list_cache[ROOT] = { data = CANNED_LIST, at = (vim.uv or vim.loop).now() }
  return buf
end

local function line_value(buf, key)
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local v = l:match("^%s*" .. key .. ":%s*(.*)$")
    if v then
      return (v:gsub("%s+$", ""))
    end
  end
  return nil
end

local ENUM_FIELDS = { config = { wizard = { fields = { "status", "type", "priority" } } } }

describe("wizard (layer 2)", function()
  after_each(function()
    if wizard._state then
      wizard.finish(wizard._state)
    end
    vim.cmd("silent! stopinsert")
  end)

  describe("wizard enum flow", function()
    local BEAN = {
      "---",
      "# beans-self",
      "title: This bean",
      "status: todo",
      "type: task",
      "priority: low",
      "---",
      "",
      "body",
    }

    it("sequences steps and applies a mnemonic keypress with auto-advance", function()
      local buf = open_bean(BEAN, ENUM_FIELDS)
      wizard.start()
      assert.are.equal(1, wizard._state.index)
      assert.are.equal("status", wizard._state.field)

      feed("i") -- in-progress
      assert.are.equal("in-progress", line_value(buf, "status"))
      assert.are.equal(2, wizard._state.index)
      assert.are.equal("type", wizard._state.field)
    end)

    it("<Tab> on an unchanged field advances without dirtying the buffer", function()
      local buf = open_bean(BEAN, ENUM_FIELDS)
      wizard.start()
      feed("<Tab>")
      assert.are.equal("todo", line_value(buf, "status"))
      assert.are.equal(2, wizard._state.index)
    end)

    it("<S-Tab> returns to the previous step", function()
      local buf = open_bean(BEAN, ENUM_FIELDS)
      wizard.start()
      feed("i") -- advance to type
      assert.are.equal(2, wizard._state.index)
      feed("<S-Tab>")
      assert.are.equal(1, wizard._state.index)
      assert.are.equal("status", wizard._state.field)
      assert.are.equal("in-progress", line_value(buf, "status")) -- pick preserved
    end)

    it("<Esc> finishes from any step", function()
      open_bean(BEAN, ENUM_FIELDS)
      wizard.start()
      feed("t") -- advance to type
      feed("<Esc>")
      assert.is_nil(wizard._state)
    end)

    -- NOTE: insert-mode-at-finish is asserted by the layer-4 e2e (a real child
    -- nvim with a live input loop); headless `startinsert` cannot enter insert
    -- mode here. Layer 2 asserts finish, cursor-on-body, and float teardown.
    it("finishes on the last body line with the float closed", function()
      local buf = open_bean(BEAN, {
        config = {
          wizard = { fields = { "status" }, finish = { insert = false, cursor = "body_end" } },
        },
      })
      wizard.start()
      feed("i") -- apply status, advance past last => finish
      assert.is_nil(wizard._state)
      assert.are.equal(buf, vim.api.nvim_get_current_buf())
      local cur = vim.api.nvim_win_get_cursor(0)
      assert.is_true(cur[1] >= 8) -- on a body line, not the closing ---
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        assert.are_not.equal("editor", vim.api.nvim_win_get_config(win).relative)
      end
    end)
  end)

  describe("wizard undo grouping", function()
    it("makes each field one undo step (five fields, five undos restore)", function()
      local BEAN = {
        "---",
        "# beans-self",
        "title: This bean",
        "status: todo",
        "type: task",
        "priority: low",
        "tags:",
        "    - core",
        "parent: beans-e1",
        "---",
        "",
        "body line",
      }
      local buf = open_bean(BEAN, { config = { wizard = { finish = { insert = false } } } })
      local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      wizard.start()
      feed("i") -- status -> in-progress
      feed("b") -- type -> bug
      feed("h") -- priority -> high
      feed("<Space>") -- tags: uncheck core
      feed("<Tab>") -- confirm tags (now empty) -> advance to parent
      -- Parent step uses an insert-mode prompt (see NOTE above); drive it via its
      -- exposed handlers so this is deterministic headless.
      assert.are.equal("parent", wizard._state.field)
      wizard._state.parent.cursor = 1 -- first candidate (beans-m1, != current e1)
      wizard._state.parent.select() -- apply parent -> finish

      assert.is_nil(wizard._state)
      -- Five distinct changes were applied.
      assert.are_not.same(original, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

      vim.cmd("stopinsert")
      for _ = 1, 5 do
        feed("u")
      end
      assert.are.same(original, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end)
  end)

  describe("wizard tags step", function()
    it("toggles a tag and confirms", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      local buf = open_bean(BEAN, { config = { wizard = { fields = { "tags" } } } })
      wizard.start()
      assert.are.equal("tags", wizard._state.field)
      feed("<Space>") -- check the first tag in the universe
      feed("<CR>") -- confirm
      vim.wait(20)
      assert.is_nil(wizard._state)
      local body = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      assert.is_truthy(body:match("tags:"))
    end)

    it("validates a new tag and rejects an invalid one", function()
      assert.is_true(require("beans.wizard.steps.tags").valid_tag("web-ui"))
      assert.is_false(require("beans.wizard.steps.tags").valid_tag("Bad Tag"))
      assert.is_false(require("beans.wizard.steps.tags").valid_tag("1lead"))
    end)
  end)

  describe("wizard parent step", function()
    it("excludes the bean itself and filters by type", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      open_bean(BEAN, { config = { wizard = { fields = { "parent" } } } })
      wizard.start()
      assert.are.equal("parent", wizard._state.field)
      local ids = {}
      for _, c in ipairs(wizard._state.parent.filtered) do
        ids[c.id] = true
      end
      assert.is_true(ids["beans-m1"])
      assert.is_true(ids["beans-e1"])
      assert.is_nil(ids["beans-self"]) -- self excluded
    end)

    it("clears the parent via the clear entry", function()
      local BEAN =
        { "---", "# beans-self", "title: x", "status: todo", "parent: beans-e1", "---", "", "b" }
      local buf = open_bean(BEAN, { config = { wizard = { fields = { "parent" } } } })
      wizard.start()
      -- Cursor 0 is the "(clear parent)" entry.
      assert.are.equal(0, wizard._state.parent.cursor)
      wizard._state.parent.select()
      assert.is_nil(line_value(buf, "parent"))
    end)

    it("narrows candidates as the filter query changes", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      open_bean(BEAN, { config = { wizard = { fields = { "parent" } } } })
      wizard.start()
      wizard._state.parent.set_query("Milestone")
      assert.are.equal(1, #wizard._state.parent.filtered)
      assert.are.equal("beans-m1", wizard._state.parent.filtered[1].id)
    end)
  end)

  describe("wizard has no blocking prompts (§11.0)", function()
    it("uses no vim.fn.input/getchar/confirm/ui.select in lua/beans/wizard", function()
      local dir = vim.fn.getcwd() .. "/lua/beans/wizard"
      local files = vim.fn.globpath(dir, "**/*.lua", false, true)
      assert.is_true(#files >= 4)
      local forbidden = {
        "vim%.fn%.input",
        "vim%.fn%.getchar",
        "vim%.fn%.confirm",
        "vim%.ui%.select",
        "vim%.ui%.input",
      }
      for _, file in ipairs(files) do
        local content = table.concat(vim.fn.readfile(file), "\n")
        for _, pat in ipairs(forbidden) do
          assert.is_nil(content:match(pat), ("%s contains %s"):format(file, pat))
        end
      end
    end)
  end)
end)
