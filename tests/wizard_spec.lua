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

  -- Seed caches so data is available synchronously. `discovered` says whether
  -- Beans reported the vocabulary or the fallback table stood in for it; only a
  -- reported vocabulary may judge a configured default.
  schema._vocab_cache[ROOT] = {
    status = cfg.fallback.status,
    type = cfg.fallback.type,
    priority = cfg.fallback.priority,
    discovered = {
      status = opts.discovered or false,
      type = opts.discovered or false,
      priority = opts.discovered or false,
    },
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

    -- bug: normal-mode selection (j/k + <CR> on the candidate under the cursor).
    it("selects the candidate under the cursor in normal mode", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      local buf = open_bean(BEAN, {
        config = {
          wizard = { fields = { "parent" } },
          fields = { parent = { title_comment = false } },
        },
      })
      wizard.start()
      assert.are.equal("parent", wizard._state.field)
      feed("j") -- move off "(clear)" onto the first candidate
      feed("<CR>") -- select the candidate under the cursor
      assert.is_nil(wizard._state)
      assert.are.equal("beans-m1", line_value(buf, "parent"))
    end)

    it("writes the parent title as a trailing comment (default)", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      local buf = open_bean(BEAN, { config = { wizard = { fields = { "parent" } } } })
      wizard.start()
      feed("j") -- first candidate (beans-m1 "Milestone one")
      feed("<CR>")
      assert.are.equal("beans-m1 # Milestone one", line_value(buf, "parent"))
    end)

    it("omits the comment when title_comment = false", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      local buf = open_bean(BEAN, {
        config = {
          wizard = { fields = { "parent" } },
          fields = { parent = { title_comment = false } },
        },
      })
      wizard.start()
      feed("j")
      feed("<CR>")
      assert.are.equal("beans-m1", line_value(buf, "parent"))
    end)

    -- bug: the parent card must not show the previous step's content.
    it("shows no stale content from the previous step", function()
      local BEAN = {
        "---",
        "# beans-self",
        "title: x",
        "status: todo",
        "tags:",
        "    - core",
        "---",
        "",
        "b",
      }
      open_bean(BEAN, { config = { wizard = { fields = { "tags", "parent" } } } })
      wizard.start()
      feed("<Tab>") -- confirm tags -> advance to parent
      assert.are.equal("parent", wizard._state.field)
      assert.are.equal("", wizard._state.parent.query) -- filter starts empty
      local lines = vim.api.nvim_buf_get_lines(wizard._state.ui.buf, 0, -1, false)
      for _, l in ipairs(lines) do
        assert.is_nil(l:match("%[.%]"), "stale tag checkbox on parent card: " .. l)
      end
      assert.is_truthy(table.concat(lines, "\n"):match("%(clear parent%)"))
    end)

    it("offers only milestones and epics by default", function()
      local BEAN = { "---", "# beans-self", "title: x", "status: todo", "---", "", "b" }
      open_bean(BEAN, { config = { wizard = { fields = { "parent" } } } })
      wizard.start()
      for _, c in ipairs(wizard._state.parent.filtered) do
        assert.is_true(c.type == "milestone" or c.type == "epic", "unexpected type: " .. c.type)
      end
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

describe("wizard enum defaults", function()
  -- What `beans create` actually writes: status and type from .beans.yml, and no
  -- priority key at all, because Beans has no default_priority.
  local NO_PRIORITY = {
    "---",
    "# beans-self",
    "title: This bean",
    "status: todo",
    "type: task",
    "---",
    "",
    "body",
  }

  -- Index of "normal" in the seeded priority vocabulary:
  -- critical, high, normal, low, deferred.
  local NORMAL_INDEX = 3

  local function priority_only(field_opts)
    return {
      config = {
        wizard = { fields = { "priority" }, finish = { insert = false } },
        fields = { priority = field_opts },
      },
    }
  end

  local orig_notify

  before_each(function()
    orig_notify = vim.notify
    schema._default_warned = {}
  end)

  after_each(function()
    vim.notify = orig_notify
    if wizard._state then
      wizard.finish(wizard._state)
    end
    vim.cmd("silent! stopinsert")
  end)

  local function capture_notifies()
    local notes = {}
    vim.notify = function(msg, lvl)
      table.insert(notes, { msg = msg, lvl = lvl })
    end
    return notes
  end

  it("starts the cursor on the configured default when the field is unset", function()
    open_bean(NO_PRIORITY, priority_only({ default = "normal" }))
    wizard.start()
    assert.are.equal("priority", wizard._state.field)
    assert.are.equal(NORMAL_INDEX, wizard._state.cursor)
  end)

  it("opening the step writes nothing", function()
    local buf = open_bean(NO_PRIORITY, priority_only({ default = "normal" }))
    local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    wizard.start()
    assert.are.same(before, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.is_nil(line_value(buf, "priority"))
  end)

  it("<Tab> past a defaulted field leaves it unset", function()
    local buf = open_bean(NO_PRIORITY, priority_only({ default = "normal" }))
    wizard.start()
    feed("<Tab>") -- the only field, so this advances past the end and finishes
    assert.is_nil(line_value(buf, "priority"))
    assert.is_nil(wizard._state)
  end)

  it("<CR> on a defaulted field writes the default", function()
    local buf = open_bean(NO_PRIORITY, priority_only({ default = "normal" }))
    wizard.start()
    feed("<CR>")
    assert.are.equal("normal", line_value(buf, "priority"))
  end)

  it("starts on the first option when no default is configured", function()
    open_bean(NO_PRIORITY, priority_only({}))
    wizard.start()
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("a value already set wins over the configured default", function()
    local set = vim.deepcopy(NO_PRIORITY)
    table.insert(set, 6, "priority: high")
    open_bean(set, priority_only({ default = "normal" }))
    wizard.start()
    assert.are.equal(2, wizard._state.cursor) -- high, not normal
  end)

  it("a set but unrecognised value suppresses the default", function()
    local set = vim.deepcopy(NO_PRIORITY)
    table.insert(set, 6, "priority: urgent")
    open_bean(set, priority_only({ default = "normal" }))
    wizard.start()
    -- The field is set, so the default must not take over the cursor even though
    -- no option matches the value in the file.
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("places the cursor on a default for status too", function()
    open_bean({
      "---",
      "# beans-self",
      "title: This bean",
      "type: task",
      "---",
      "",
      "body",
    }, {
      config = {
        wizard = { fields = { "status" }, finish = { insert = false } },
        fields = { status = { default = "draft" } },
      },
    })
    wizard.start()
    assert.are.equal(3, wizard._state.cursor) -- in-progress, todo, draft
  end)

  it("warns once and falls back when the default is outside the vocabulary", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    open_bean(NO_PRIORITY, opts)
    local notes = capture_notifies()
    wizard.start()
    assert.are.equal(1, #notes)
    assert.is_truthy(notes[1].msg:match("fields%.priority%.default"))
    assert.is_truthy(notes[1].msg:match("urgent"))
    assert.is_truthy(notes[1].msg:match("critical")) -- names the accepted values
    assert.are.equal(vim.log.levels.WARN, notes[1].lvl)
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("does not repeat the warning when the step re-renders", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    open_bean(NO_PRIORITY, opts)
    local notes = capture_notifies()
    wizard.start()
    wizard.refresh(wizard._state)
    wizard.refresh(wizard._state)
    assert.are.equal(1, #notes)
  end)

  it("does not repeat the warning on a later wizard in the same project", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    open_bean(NO_PRIORITY, opts)
    local notes = capture_notifies()
    wizard.start()
    wizard.finish(wizard._state)
    open_bean(NO_PRIORITY, opts)
    wizard.start()
    assert.are.equal(1, #notes)
  end)

  it("stays silent while the fallback table is standing in", function()
    -- discovered is false: Beans never reported this vocabulary, so a later
    -- render might still find the value and the warning would be retracted.
    local opts = priority_only({ default = "urgent" })
    opts.discovered = false
    open_bean(NO_PRIORITY, opts)
    local notes = capture_notifies()
    wizard.start()
    assert.are.equal(0, #notes)
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("stays silent when the vocabulary has not resolved yet", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    open_bean(NO_PRIORITY, opts)
    wizard.start()
    -- Re-render in the state the step sees before the async read lands.
    local notes = capture_notifies()
    schema._default_warned = {}
    wizard._state.data.vocab = nil
    wizard.refresh(wizard._state)
    assert.are.equal(0, #notes)
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("stays silent on a buffer with no project root", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    local buf = open_bean(NO_PRIORITY, opts)
    vim.b[buf].beans = { id = "beans-self", bufnr = buf }
    local notes = capture_notifies()
    wizard.start()
    assert.are.equal(0, #notes)
    assert.are.equal(1, wizard._state.cursor)
  end)

  it("honours notify = false", function()
    local opts = priority_only({ default = "urgent" })
    opts.discovered = true
    opts.config.notify = false
    open_bean(NO_PRIORITY, opts)
    local notes = capture_notifies()
    wizard.start()
    assert.are.equal(0, #notes)
    assert.are.equal(1, wizard._state.cursor)
  end)
end)
