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
