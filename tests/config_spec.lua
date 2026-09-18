-- config_spec.lua — defaults, deep merge, validate-and-warn (§7.3, §11.1).

local config = require("beans.config")

describe("beans config", function()
  it("loads and setup() succeeds with no arguments", function()
    local beans = require("beans")
    assert.has_no.errors(function()
      beans.setup()
    end)
    assert.is_table(beans.config)
    assert.are.equal("beans", beans.config.executable)
    assert.are.same({ "status", "type", "priority", "tags", "parent" }, beans.config.wizard.fields)
  end)

  it("empty-table setup equals full defaults", function()
    local beans = require("beans")
    beans.setup({})
    assert.are.equal(5000, beans.config.timeout)
    assert.is_true(beans.config.keymaps.enabled)
  end)

  it("defaults parent candidate types to milestones and epics only", function()
    assert.are.same({ "milestone", "epic" }, config.merge().fields.parent.types)
  end)

  it("defaults fields.parent.title_comment to true", function()
    assert.is_true(config.merge().fields.parent.title_comment)
  end)

  it("leaves every enum field default unset out of the box", function()
    local beans = require("beans")
    beans.setup()
    for _, field in ipairs({ "status", "type", "priority" }) do
      assert.is_nil(beans.config.fields[field].default)
    end
    -- The sibling that shares the priority entry is untouched.
    assert.is_true(beans.config.fields.priority.allow_clear)
  end)

  it("setting one enum default preserves its siblings", function()
    local merged = config.merge({ fields = { priority = { default = "normal" } } })
    assert.are.equal("normal", merged.fields.priority.default)
    assert.is_true(merged.fields.priority.allow_clear)
    assert.is_true(merged.fields.tags.normalize)
    assert.is_true(merged.fields.tags.validate)
    assert.are.same({ "milestone", "epic" }, merged.fields.parent.types)
    assert.is_nil(merged.fields.status.default)
  end)

  it("exposes the version from the VERSION file", function()
    local v = require("beans").version
    assert.is_string(v)
    assert.are_not.equal("unknown", v)
    assert.is_truthy(v:match("^%d+%.%d+%.%d+$"))
  end)

  it("merges a partial table without wiping siblings", function()
    local merged = config.merge({
      wizard = { window = { border = "single" } },
      keymaps = { wizard = "<leader>x" },
    })
    -- Sibling defaults survive.
    assert.are.equal("cursor", merged.wizard.window.position)
    assert.are.equal("single", merged.wizard.window.border)
    assert.are.equal("<leader>bb", merged.keymaps.menu)
    assert.are.equal("<leader>x", merged.keymaps.wizard)
  end)

  it("exposes every module as a requirable stub", function()
    for _, mod in ipairs({
      "beans.health",
      "beans.project",
      "beans.detect",
      "beans.cli",
      "beans.schema",
      "beans.frontmatter",
      "beans.completion",
      "beans.actions",
      "beans.wizard",
      "beans.wizard.ui",
      "beans.wizard.steps.enum",
      "beans.wizard.steps.tags",
      "beans.wizard.steps.parent",
    }) do
      assert.has_no.errors(function()
        require(mod)
      end)
    end
  end)
end)

describe("beans config validation", function()
  it("substitutes the default for a wrong-typed value and records a warning", function()
    local cfg = config.merge({})
    cfg.executable = 123
    cfg.timeout = "nope"
    local _, warnings = config.validate(cfg)
    assert.are.equal("beans", cfg.executable)
    assert.are.equal(5000, cfg.timeout)
    assert.are.equal(2, #warnings)
  end)

  it("accepts notify = false", function()
    local cfg = config.merge({ notify = false })
    local _, warnings = config.validate(cfg)
    assert.are.equal(0, #warnings)
    assert.is_false(cfg.notify)
  end)

  it("drops a non-string enum default with one warning", function()
    local cfg = config.merge({ fields = { priority = { default = 3 } } })
    local _, warnings = config.validate(cfg)
    assert.is_nil(cfg.fields.priority.default)
    assert.are.equal(1, #warnings)
    assert.is_truthy(warnings[1]:match("fields%.priority%.default"))
    -- Dropping the default leaves the rest of the entry alone.
    assert.is_true(cfg.fields.priority.allow_clear)
  end)

  it("keeps a string default that no vocabulary contains", function()
    -- Vocabularies are discovered per project at runtime, so setup cannot judge
    -- the value; the wizard checks it when the step opens.
    local cfg = config.merge({ fields = { priority = { default = "urgent" } } })
    local _, warnings = config.validate(cfg)
    assert.are.equal("urgent", cfg.fields.priority.default)
    assert.are.equal(0, #warnings)
  end)
end)

describe("beans config.warn", function()
  local orig_notify

  before_each(function()
    orig_notify = vim.notify
  end)
  after_each(function()
    vim.notify = orig_notify
  end)

  local function capture(cfg)
    local notes = {}
    vim.notify = function(msg, lvl)
      table.insert(notes, { msg = msg, lvl = lvl })
    end
    config.warn(cfg, "beans.nvim: test message")
    return notes
  end

  it("emits at WARN under the default level", function()
    local notes = capture(config.merge())
    assert.are.equal(1, #notes)
    assert.are.equal(vim.log.levels.WARN, notes[1].lvl)
  end)

  it("stays silent when notify is false", function()
    assert.are.equal(0, #capture(config.merge({ notify = false })))
  end)

  it("stays silent when the level is above WARN", function()
    assert.are.equal(0, #capture(config.merge({ notify = vim.log.levels.ERROR })))
  end)
end)

describe("beans setup validation", function()
  local orig_notify

  before_each(function()
    orig_notify = vim.notify
  end)
  after_each(function()
    vim.notify = orig_notify
  end)

  it("warns once and falls back on an invalid value", function()
    local notes = {}
    vim.notify = function(msg, lvl)
      table.insert(notes, { msg = msg, lvl = lvl })
    end
    require("beans").setup({ executable = 123 })
    assert.are.equal("beans", require("beans").config.executable)
    assert.are.equal(1, #notes)
  end)

  it("notify = false suppresses warnings but still falls back", function()
    local notes = {}
    vim.notify = function(msg, lvl)
      table.insert(notes, { msg = msg, lvl = lvl })
    end
    require("beans").setup({ executable = 123, notify = false })
    assert.are.equal("beans", require("beans").config.executable)
    assert.are.equal(0, #notes)
  end)

  it("does not error when the beans binary is missing", function()
    assert.has_no.errors(function()
      require("beans").setup({ executable = "beans-does-not-exist-xyz" })
    end)
  end)
end)
