-- detect_spec.lua — bean detection, zero-footprint, auto-start (Milestone 02).

local detect = require("beans.detect")
local beans = require("beans")

local BEAN_LINES = {
  "---",
  "# beans-0001",
  "title: A sample bean",
  "status: todo",
  "type: task",
  "---",
  "",
  "body",
}

local function tmp_project()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. "/.beans/archive", "p")
  local fd = assert(io.open(root .. "/.beans.yml", "w"))
  fd:write("beans:\n    path: .beans\n")
  fd:close()
  return vim.fs.normalize(root)
end

--- Make a scratch buffer with the given name and lines.
local function make_buffer(name, lines)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
  return bufnr
end

local config

describe("beans.detect content signature", function()
  it("recognises frontmatter with an id comment and title", function()
    assert.are.equal("beans-0001", detect.content_id(BEAN_LINES))
  end)

  it("rejects when line 1 is not exactly ---", function()
    assert.is_nil(detect.content_id({ "# heading", "title: x" }))
  end)

  it("rejects frontmatter missing the id comment", function()
    assert.is_nil(detect.content_id({ "---", "title: x", "---" }))
  end)

  it("extracts id from a filename", function()
    assert.are.equal("beans-0abc", detect.id_from_filename("/x/.beans/beans-0abc--the-slug.md"))
    assert.is_nil(detect.id_from_filename("/x/notes.md"))
  end)
end)

describe("beans.detect", function()
  before_each(function()
    config = require("beans.config").merge()
    -- Use the hermetic stub so attach()'s prefetch never hits the real CLI.
    config.executable = vim.fn.getcwd() .. "/tests/fixtures/fake-beans"
    beans.config = config
  end)

  it("detects a bean by path", function()
    local root = tmp_project()
    local bufnr = make_buffer(root .. "/.beans/beans-0001--sample.md", BEAN_LINES)
    local ctx = detect.detect(bufnr, config)
    assert.is_not_nil(ctx)
    assert.are.equal("beans-0001", ctx.id)
    assert.are.equal(root, ctx.root)
    assert.are.equal(root .. "/.beans", ctx.beans_dir)
  end)

  it("detects a bean in the archive directory", function()
    local root = tmp_project()
    local bufnr = make_buffer(root .. "/.beans/archive/beans-0002--old.md", BEAN_LINES)
    local ctx = detect.detect(bufnr, config)
    assert.is_not_nil(ctx)
  end)

  it("detects a bean by content outside any project", function()
    local bufnr = make_buffer(vim.fn.tempname() .. "/loose.md", BEAN_LINES)
    local ctx = detect.detect(bufnr, config)
    assert.is_not_nil(ctx)
    assert.are.equal("beans-0001", ctx.id)
    assert.is_nil(ctx.root)
  end)

  it("attaches nothing to plain markdown outside a project", function()
    local bufnr = make_buffer(vim.fn.tempname() .. "/notes.md", { "# Notes", "", "just markdown" })
    assert.is_nil(detect.detect(bufnr, config))

    beans.on_buffer(bufnr)
    assert.is_nil(vim.b[bufnr].beans)
    assert.are.equal(0, #vim.api.nvim_buf_get_keymap(bufnr, "n"))
  end)

  it("sets vim.b.beans and buffer-local keymaps on a bean buffer", function()
    local root = tmp_project()
    local bufnr = make_buffer(root .. "/.beans/beans-0001--sample.md", BEAN_LINES)
    beans.on_buffer(bufnr)
    assert.is_not_nil(vim.b[bufnr].beans)
    assert.are.equal("beans-0001", vim.b[bufnr].beans.id)
    assert.is_true(#vim.api.nvim_buf_get_keymap(bufnr, "n") > 0)
  end)
end)

describe("beans.detect auto-start heuristic", function()
  -- True UTC epoch for 2026-03-07T12:00:00Z, via the same converter the
  -- implementation uses, so this test is timezone-independent.
  local NOW = detect.parse_created_at({ "created_at: 2026-03-07T12:00:00Z" })

  local function bean_with(created_at, body)
    local lines =
      { "---", "# beans-0001", "title: x", ("created_at: %s"):format(created_at), "---" }
    for _, l in ipairs(body or {}) do
      table.insert(lines, l)
    end
    return lines
  end

  it("fires on a fresh empty bean", function()
    local lines = bean_with("2026-03-07T11:59:50Z", { "", "  " })
    assert.is_true(detect.should_autostart(lines, { enabled = true, max_age_seconds = 30 }, NOW))
  end)

  it("does not fire on an old bean", function()
    local lines = bean_with("2026-03-07T10:00:00Z", { "" })
    assert.is_false(detect.should_autostart(lines, { enabled = true, max_age_seconds = 30 }, NOW))
  end)

  it("does not fire when the body is non-empty", function()
    local lines = bean_with("2026-03-07T11:59:55Z", { "already writing" })
    assert.is_false(
      detect.should_autostart(
        lines,
        { enabled = true, max_age_seconds = 30, require_empty_body = true },
        NOW
      )
    )
  end)

  it("does not fire when disabled", function()
    local lines = bean_with("2026-03-07T11:59:55Z", { "" })
    assert.is_false(detect.should_autostart(lines, { enabled = false, max_age_seconds = 30 }, NOW))
  end)
end)
