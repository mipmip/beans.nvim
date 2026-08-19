-- config_spec.lua — scaffolding smoke tests.
--
-- Full configuration coverage (defaults, validate-and-warn, partial merge of
-- the §7.3 table) is added in Milestone 04 (`configuration`). For now these
-- assert the acceptance criteria of the scaffolding epic: the module loads and
-- `setup()` is safe with or without arguments.

describe("beans scaffolding", function()
  it("loads and setup() succeeds with no arguments", function()
    local beans = require("beans")
    assert.has_no.errors(function()
      beans.setup()
    end)
    assert.is_table(beans.config)
  end)

  it("merges a partial table without wiping siblings", function()
    local config = require("beans.config")
    config.defaults = { a = { x = 1, y = 2 }, b = 3 }
    local merged = config.merge({ a = { y = 9 } })
    assert.are.equal(1, merged.a.x)
    assert.are.equal(9, merged.a.y)
    assert.are.equal(3, merged.b)
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
