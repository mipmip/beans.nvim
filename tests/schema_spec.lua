-- schema_spec.lua — vocab discovery, mnemonics, fallback (Milestone 02).

local schema = require("beans.schema")

local HELP = table.concat({
  "Flags:",
  "  -s, --status string     New status (in-progress, todo, draft, completed, scrapped)",
  "  -t, --type string       New type (milestone, epic, bug, feature, task)",
  "  -p, --priority string   New priority (critical, high, normal, low, deferred, or empty to clear)",
  "      --title string      New title",
}, "\n")

describe("beans.schema vocab parsing", function()
  it("parses status/type/priority from --help", function()
    local vocab = schema.parse_vocab(HELP)
    assert.are.same({ "in-progress", "todo", "draft", "completed", "scrapped" }, vocab.status)
    assert.are.same({ "milestone", "epic", "bug", "feature", "task" }, vocab.type)
  end)

  it("drops the 'or empty to clear' tail from priority", function()
    local vocab = schema.parse_vocab(HELP)
    assert.are.same({ "critical", "high", "normal", "low", "deferred" }, vocab.priority)
  end)

  it("returns nil for a field that is not present", function()
    assert.is_nil(schema.parse_field(HELP, "nonexistent"))
    assert.is_nil(schema.parse_field("", "status"))
  end)
end)

describe("beans.schema mnemonics", function()
  it("assigns collision-free first letters for the default status vocab", function()
    local m = schema.assign_mnemonics({ "in-progress", "todo", "draft", "completed", "scrapped" })
    assert.are.equal("i", m["in-progress"])
    assert.are.equal("t", m["todo"])
    assert.are.equal("d", m["draft"])
    assert.are.equal("c", m["completed"])
    assert.are.equal("s", m["scrapped"])
  end)

  it("uses the next unused letter on a first-letter collision", function()
    local m = schema.assign_mnemonics({ "alpha", "apex" })
    assert.are.equal("a", m["alpha"])
    assert.are.equal("p", m["apex"]) -- 'a' taken, next unused letter in "apex"
  end)

  it("falls through to digits when no letter is available", function()
    local m = schema.assign_mnemonics({ "a", "aa" })
    assert.are.equal("a", m["a"])
    assert.are.equal("1", m["aa"]) -- only letter 'a' is taken -> digit
  end)

  it("honours explicit overrides", function()
    local m = schema.assign_mnemonics({ "todo", "draft" }, { todo = "w" })
    assert.are.equal("w", m["todo"])
    assert.are.equal("d", m["draft"])
  end)
end)

describe("beans.schema discovery (async)", function()
  local fake = vim.fn.getcwd() .. "/tests/fixtures/fake-beans"

  local function tmpdir()
    local d = vim.fn.tempname()
    vim.fn.mkdir(d, "p")
    return d
  end

  it("discovers vocab via the beans CLI", function()
    schema._vocab_cache = {}
    local vocab
    schema.get_vocab({ executable = fake }, { root = tmpdir() }, function(v)
      vocab = v
    end)
    vim.wait(3000, function()
      return vocab ~= nil
    end, 20)
    assert.is_not_nil(vocab)
    assert.are.same({ "in-progress", "todo", "draft", "completed", "scrapped" }, vocab.status)
  end)

  it("falls back to the config table when the binary is missing", function()
    schema._vocab_cache = {}
    local fallback = require("beans.config").defaults.fallback
    local vocab
    schema.get_vocab(
      { executable = "beans-does-not-exist-xyz", fallback = fallback },
      { root = tmpdir() },
      function(v)
        vocab = v
      end
    )
    vim.wait(3000, function()
      return vocab ~= nil
    end, 20)
    assert.is_not_nil(vocab)
    assert.are.same(fallback.status, vocab.status)
  end)
end)
