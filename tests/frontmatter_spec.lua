-- frontmatter_spec.lua — unit coverage for the pure frontmatter engine.
--
-- Values (quoting, tag indentation) are asserted against what the real Beans
-- CLI emits, verified with go-yaml v3 during Milestone 02.

local fm = require("beans.frontmatter")

-- A fully-populated bean, mirroring beans-nvim-briefing.md §2.1.
local function full_bean()
  return {
    "---",
    "# beans-0ajg",
    "title: beans complete command",
    "status: todo",
    "type: task",
    "priority: normal",
    "created_at: 2025-12-27T21:44:04Z",
    "updated_at: 2026-03-07T23:10:48Z",
    "order: VV",
    "parent: beans-mmyp",
    "---",
    "",
    "Body text.",
  }
end

-- A minimal bean: only the two required keys.
local function minimal_bean()
  return {
    "---",
    "# beans-xxxx",
    "title: minimal",
    "status: todo",
    "---",
    "",
  }
end

local function index_of(lines, needle)
  for i, l in ipairs(lines) do
    if l == needle then
      return i
    end
  end
  return nil
end

describe("frontmatter.find_block", function()
  it("locates the fences of a bean", function()
    local block = fm.find_block(full_bean())
    assert.are.equal(1, block.open)
    assert.are.equal(11, block.close)
  end)

  it("returns nil when line 1 is not exactly ---", function()
    assert.is_nil(fm.find_block({ "# not a bean", "title: x" }))
    assert.is_nil(fm.find_block({ "----", "x", "---" }))
  end)
end)

describe("frontmatter not-a-bean guard", function()
  it("makes no edits and reports not-a-bean", function()
    local input = { "# plain markdown", "", "some text" }
    local out, ok = fm.set_scalar(input, "status", "todo")
    assert.is_false(ok)
    assert.are.same(input, out)
  end)
end)

describe("frontmatter.set_scalar (replace)", function()
  it("replaces an existing scalar value", function()
    local out = fm.set_scalar(full_bean(), "status", "in-progress")
    assert.is_not_nil(index_of(out, "status: in-progress"))
    assert.is_nil(index_of(out, "status: todo"))
  end)

  it("is a byte-identical no-op when the value is unchanged", function()
    local input = full_bean()
    local out = fm.set_scalar(input, "status", "todo")
    assert.are.same(input, out)
  end)

  it("never touches the id comment, created_at, updated_at, or order", function()
    local out = fm.set_scalar(full_bean(), "priority", "high")
    assert.is_not_nil(index_of(out, "# beans-0ajg"))
    assert.is_not_nil(index_of(out, "created_at: 2025-12-27T21:44:04Z"))
    assert.is_not_nil(index_of(out, "updated_at: 2026-03-07T23:10:48Z"))
    assert.is_not_nil(index_of(out, "order: VV"))
  end)
end)

describe("frontmatter.set_scalar (insert at canonical position)", function()
  local function keys_in_order(lines)
    local block = fm.find_block(lines)
    local keys = {}
    for i = block.open + 1, block.close - 1 do
      local k = lines[i]:match("^([%w_]+):")
      if k then
        keys[#keys + 1] = k
      end
    end
    return keys
  end

  it("inserts type when missing (before priority)", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "priority: normal",
      "---",
    }
    local out = fm.set_scalar(input, "type", "bug")
    assert.are.same({ "title", "status", "type", "priority" }, keys_in_order(out))
  end)

  it("inserts priority when missing (between type and created_at)", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "type: task",
      "created_at: X",
      "---",
    }
    local out = fm.set_scalar(input, "priority", "high")
    assert.are.same({ "title", "status", "type", "priority", "created_at" }, keys_in_order(out))
  end)

  it("inserts parent when missing (after order, before blocking)", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "order: VV",
      "blocking: beans-zzzz",
      "---",
    }
    local out = fm.set_scalar(input, "parent", "beans-mmyp")
    assert.are.same({ "title", "status", "order", "parent", "blocking" }, keys_in_order(out))
  end)

  it("inserts a missing scalar into a title+status-only bean", function()
    local out = fm.set_scalar(minimal_bean(), "type", "feature")
    assert.are.same({ "title", "status", "type" }, keys_in_order(out))
  end)

  it("appends before the closing fence when no later-ranked key exists", function()
    local out = fm.set_scalar(minimal_bean(), "parent", "beans-mmyp")
    assert.are.same({ "title", "status", "parent" }, keys_in_order(out))
  end)
end)

describe("frontmatter.clear_scalar", function()
  it("removes the priority line entirely", function()
    local out = fm.clear_scalar(full_bean(), "priority")
    for _, l in ipairs(out) do
      assert.is_nil(l:match("^priority:"))
    end
  end)

  it("is a no-op when the key is absent", function()
    local input = minimal_bean()
    local out = fm.clear_scalar(input, "priority")
    assert.are.same(input, out)
  end)
end)

describe("frontmatter.set_list / clear_list (tags)", function()
  it("inserts a tags block with 4-space item indentation in canonical order", function()
    local out = fm.set_list(minimal_bean(), "tags", { "foo", "bar-baz" })
    local ti = index_of(out, "tags:")
    assert.is_not_nil(ti)
    assert.are.equal("    - foo", out[ti + 1])
    assert.are.equal("    - bar-baz", out[ti + 2])
    -- tags sits after status (canonical order) in a minimal bean
    assert.are.equal("status: todo", out[ti - 1])
  end)

  it("replaces an existing tags block, preserving its indentation", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "tags:",
      "    - old",
      "created_at: X",
      "---",
    }
    local out = fm.set_list(input, "tags", { "new" })
    local ti = index_of(out, "tags:")
    assert.are.equal("    - new", out[ti + 1])
    assert.are.equal("created_at: X", out[ti + 2])
    assert.is_nil(index_of(out, "    - old"))
  end)

  it("clears the whole tags block", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "tags:",
      "    - a",
      "    - b",
      "created_at: X",
      "---",
    }
    local out = fm.clear_list(input, "tags")
    assert.is_nil(index_of(out, "tags:"))
    assert.is_nil(index_of(out, "    - a"))
    assert.is_nil(index_of(out, "    - b"))
    assert.is_not_nil(index_of(out, "created_at: X"))
  end)

  it("set_list with no items clears the block", function()
    local input = {
      "---",
      "# id",
      "title: t",
      "status: todo",
      "tags:",
      "    - a",
      "---",
    }
    local out = fm.set_list(input, "tags", {})
    assert.is_nil(index_of(out, "tags:"))
  end)
end)

describe("frontmatter quoting (matches Beans / go-yaml v3)", function()
  local function title_line(value)
    local out = fm.set_scalar(minimal_bean(), "title", value)
    for _, l in ipairs(out) do
      if l:match("^title:") then
        return l
      end
    end
  end

  it("leaves a plain title unquoted", function()
    assert.are.equal("title: plain simple title", title_line("plain simple title"))
  end)

  it("single-quotes a title containing a colon", function()
    assert.are.equal(
      "title: 'beans complete: the command'",
      title_line("beans complete: the command")
    )
  end)

  it("single-quotes a title containing a hash", function()
    assert.are.equal("title: 'has # hash'", title_line("has # hash"))
  end)

  it("single-quotes a title with trailing space", function()
    assert.are.equal("title: 'trailing space '", title_line("trailing space "))
  end)

  it("leaves a mid-string apostrophe unquoted (plain)", function()
    assert.are.equal("title: it's mine", title_line("it's mine"))
  end)

  it("leaves a mid-string double-quote unquoted (plain)", function()
    assert.are.equal('title: say "hi" there', title_line('say "hi" there'))
  end)

  it("double-quotes a type-ambiguous word", function()
    assert.are.equal('title: "yes"', title_line("yes"))
  end)

  it("double-quotes a numeric-looking title", function()
    assert.are.equal('title: "12345"', title_line("12345"))
  end)

  it("escapes an embedded apostrophe when single-quoting is forced", function()
    -- colon forces single quotes; the apostrophe is doubled
    assert.are.equal("title: 'it''s: mine'", title_line("it's: mine"))
  end)
end)

describe("frontmatter.set_scalar (trailing comment)", function()
  local BEAN = {
    "---",
    "# beans-0001",
    "title: A bean",
    "status: todo",
    "parent: beans-0002",
    "---",
    "",
    "body",
  }

  local function parent_line(lines)
    for _, l in ipairs(lines) do
      if l:match("^parent:") then
        return l
      end
    end
  end

  it("appends the comment after the serialized value", function()
    local out = fm.set_scalar(BEAN, "parent", "beans-0003", "03 The Wizard")
    assert.are.equal("parent: beans-0003 # 03 The Wizard", parent_line(out))
  end)

  it("does not stack comments when replacing a commented value", function()
    local first = fm.set_scalar(BEAN, "parent", "beans-0003", "Old title")
    local second = fm.set_scalar(first, "parent", "beans-0004", "New title")
    assert.are.equal("parent: beans-0004 # New title", parent_line(second))
  end)

  it("is byte-identical to a plain set when no comment is given", function()
    local with_nil = fm.set_scalar(BEAN, "parent", "beans-0003")
    local with_empty = fm.set_scalar(BEAN, "parent", "beans-0003", "")
    assert.are.equal("parent: beans-0003", parent_line(with_nil))
    assert.are.same(with_nil, with_empty)
  end)

  it("keeps value quoting independent of the comment", function()
    -- a title-with-colon value is single-quoted; the comment stays outside it
    local out = fm.set_scalar(BEAN, "title", "a: b", "note")
    assert.are.equal("title: 'a: b' # note", out[3])
  end)
end)
