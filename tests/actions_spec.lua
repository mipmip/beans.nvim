-- actions_spec.lua — random-access :Bean / :Bean <field> (Milestone 04).

local actions = require("beans.actions")

describe("beans.actions", function()
  local orig_select, started

  before_each(function()
    orig_select = vim.ui.select
    started = nil
    -- Stub the wizard so we can assert dispatch without opening a float.
    package.loaded["beans.wizard"] = {
      start = function(opts)
        started = opts
      end,
    }
  end)

  after_each(function()
    vim.ui.select = orig_select
    package.loaded["beans.wizard"] = nil
    vim.b.beans = nil
  end)

  it("field() starts the wizard scoped to one field when on a bean", function()
    vim.b.beans = { id = "beans-1", root = "/x", beans_dir = "/x/.beans", bufnr = 0 }
    actions.field("status")
    assert.is_table(started)
    assert.are.same({ "status" }, started.fields)
  end)

  it("field() rejects an unknown field", function()
    vim.b.beans = { id = "beans-1" }
    actions.field("bogus")
    assert.is_nil(started)
  end)

  it("field() no-ops (warns) off a bean buffer", function()
    vim.b.beans = nil
    actions.field("status")
    assert.is_nil(started)
  end)

  it("menu() routes the chosen field through field()", function()
    vim.b.beans = { id = "beans-1" }
    vim.ui.select = function(items, _opts, on_choice)
      on_choice(items[2]) -- "type"
    end
    actions.menu()
    assert.is_table(started)
    assert.are.same({ "type" }, started.fields)
  end)
end)
