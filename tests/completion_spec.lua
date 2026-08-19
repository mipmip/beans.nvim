-- completion_spec.lua — omnifunc context gate + optional sources (Milestone 04).

local completion = require("beans.completion")
local schema = require("beans.schema")

local ROOT = "/tmp/beans-completion-spec"

local LIST = {
  { id = "beans-a", title = "Alpha", type = "milestone", tags = { "core", "ui" } },
  { id = "beans-b", title = "Beta", type = "epic", tags = { "core", "docs" } },
  { id = "beans-self", title = "This", type = "feature", tags = {} },
}

local BEAN = {
  "---", -- 1
  "# beans-self", -- 2
  "title: This", -- 3
  "status: ", -- 4
  "type: task", -- 5
  "tags:", -- 6
  "    - ", -- 7
  "parent: ", -- 8
  "priority: ", -- 9
  "---", -- 10
  "", -- 11
  "body text", -- 12
}

local counter = 0

--- Open the bean, seed caches, position the cursor at (row, col).
local function open_at(row, col)
  counter = counter + 1
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, ROOT .. "/.beans/beans-self-" .. counter .. "--x.md")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, BEAN)
  vim.api.nvim_set_current_buf(buf)
  vim.b[buf].beans = { id = "beans-self", root = ROOT, beans_dir = ROOT .. "/.beans", bufnr = buf }
  schema._vocab_cache[ROOT] = {
    status = { "in-progress", "todo", "draft", "completed", "scrapped" },
    type = { "milestone", "epic", "bug", "feature", "task" },
    priority = { "critical", "high", "normal", "low", "deferred" },
  }
  schema._list_cache[ROOT] = { data = LIST, at = (vim.uv or vim.loop).now() }
  vim.api.nvim_win_set_cursor(0, { row, col })
  return buf
end

describe("beans.completion omnifunc", function()
  it("completes status values after 'status:' in the frontmatter", function()
    open_at(4, #"status: ")
    local start = completion.omnifunc(1, "")
    assert.is_true(start >= 0) -- a completable position (exact col: insert mode / e2e)
    local matches = completion.omnifunc(0, "")
    local words = vim.tbl_map(function(m)
      return m.word
    end, matches)
    assert.are.same({ "in-progress", "todo", "draft", "completed", "scrapped" }, words)
  end)

  it("filters candidates by the typed base", function()
    open_at(4, #"status: ")
    completion.omnifunc(1, "")
    local matches = completion.omnifunc(0, "co")
    assert.are.equal(1, #matches)
    assert.are.equal("completed", matches[1].word)
  end)

  it("completes the tag universe on a tags list item", function()
    open_at(7, #"    - ")
    assert.is_true(completion.omnifunc(1, "") >= 0)
    local matches = completion.omnifunc(0, "")
    local words = vim.tbl_map(function(m)
      return m.word
    end, matches)
    assert.are.same({ "core", "docs", "ui" }, words)
  end)

  it("completes parent ids and excludes the bean itself", function()
    open_at(8, #"parent: ")
    completion.omnifunc(1, "")
    local matches = completion.omnifunc(0, "")
    local ids = {}
    for _, m in ipairs(matches) do
      ids[m.word] = true
    end
    assert.is_true(ids["beans-a"])
    assert.is_true(ids["beans-b"])
    assert.is_nil(ids["beans-self"])
  end)

  it("contributes nothing in the body", function()
    open_at(12, 4)
    assert.are.equal(-3, completion.omnifunc(1, ""))
  end)

  it("contributes nothing after an unknown key", function()
    open_at(3, #"title: ")
    assert.are.equal(-3, completion.omnifunc(1, ""))
  end)

  it("contributes nothing outside the frontmatter fence", function()
    open_at(11, 0)
    assert.are.equal(-3, completion.omnifunc(1, ""))
  end)
end)

describe("beans.completion optional sources", function()
  it("is a no-op and error-free when blink/cmp are disabled", function()
    assert.has_no.errors(function()
      completion.register_sources({ completion = { blink = false, cmp = false } })
    end)
  end)

  it("does not error when blink/cmp are enabled but absent", function()
    assert.has_no.errors(function()
      completion.register_sources({ completion = { blink = true, cmp = true } })
    end)
  end)
end)
