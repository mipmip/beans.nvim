-- e2e_spec.lua — layer-4 end-to-end through a real child Neovim (§11.4).
--
-- Drives a separate, real Neovim over RPC with actual terminal-style keystrokes
-- (nvim_input, not feedkeys). This is the layer that catches what unit tests
-- structurally cannot: keymaps that never attached, a float that failed to open,
-- mode-state bugs at finish. It closes the loop through the real `beans` CLI.

local cwd = vim.fn.getcwd()
local child_helper = dofile(cwd .. "/tests/helpers/child.lua")
local project = dofile(cwd .. "/tests/helpers/project.lua")

local FLOAT = "(function() for _,w in ipairs(vim.api.nvim_list_wins()) do "
  .. "local c=vim.api.nvim_win_get_config(w) if c.relative and c.relative ~= '' then return true end "
  .. "end return false end)()"

local have_beans = vim.fn.executable("beans") == 1

--- Now, as ISO-8601 UTC, so the bean looks freshly created (autostart window).
local function now_utc()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

describe("beans.nvim end-to-end", function()
  local child

  after_each(function()
    if child then
      child.stop()
      child = nil
    end
  end)

  it("runs the wizard on a TUI-created bean and beans reads back the picks", function()
    if not have_beans then
      pending("beans binary not available")
      return
    end
    -- A temp Beans project with a freshly-created, empty-bodied bean.
    local root = project.create()
    local bean = project.create_bean(root, "e2e wizard bean", { "-t", "task", "-s", "todo" })
    assert.is_truthy(bean.id)
    assert.is_truthy(bean.path ~= "" and bean.path)

    -- Rewrite it exactly as the TUI hands off: fresh created_at, empty body.
    local src = vim.fn.readfile(bean.path)
    local close
    for i = 2, #src do
      if src[i] == "---" then
        close = i
        break
      end
    end
    assert.is_truthy(close)
    local fm = {}
    for i = 1, close do
      fm[i] = src[i]
    end
    -- Ensure a fresh created_at inside the frontmatter.
    local saw_created = false
    for i = 2, close - 1 do
      if fm[i]:match("^created_at:") then
        fm[i] = "created_at: " .. now_utc()
        saw_created = true
      end
    end
    if not saw_created then
      table.insert(fm, close, "created_at: " .. now_utc())
      close = close + 1
    end
    table.insert(fm, "") -- empty body
    vim.fn.writefile(fm, bean.path)

    child = child_helper.spawn()
    if not child then
      pending("could not spawn a child Neovim")
      return
    end

    -- Open the bean; detection + autostart should raise the wizard float (which
    -- takes focus — that the float exists is the proof of detection+autostart).
    child.exec_lua(
      "local p = select(1, ...) vim.cmd('edit ' .. vim.fn.fnameescape(p))",
      { bean.path }
    )
    assert.is_true(child.await(FLOAT, 3000), "wizard float did not auto-open")

    -- Enum picks: status in-progress, type bug, priority high.
    child.input("i")
    vim.wait(80)
    child.input("b")
    vim.wait(80)
    child.input("h")
    vim.wait(80)
    -- tags: <Tab> confirms (no change) and advances to parent.
    child.input("<Tab>")
    vim.wait(80)
    -- parent is a filter-as-you-type (insert) step; <Esc> finishes from any step
    -- (equivalent end state to "skip" — the DoD's <Tab><Tab> intent).
    child.input("<Esc>")

    -- Finish: insert mode, cursor on a body line, no float.
    assert.is_true(child.await("vim.fn.mode() == 'i'", 2000), "did not land in insert mode")
    assert.is_false(child.has_float(), "a float was still open after finishing")
    local lines = child.get_lines()
    local cur = child.eval("vim.api.nvim_win_get_cursor(0)[1]")
    assert.are.equal(#lines, cur) -- last line (body), not the closing ---
    assert.are_not.equal("---", lines[cur])

    -- Save through the plugin's buffer edits, then read back via the real CLI.
    child.input("<Esc>")
    vim.wait(50)
    child.exec_lua("vim.cmd('write')")
    vim.wait(150)

    local code, out = project.beans(root, { "show", bean.id, "--json" })
    assert.are.equal(0, code)
    local ok, decoded = pcall(vim.json.decode, out)
    assert.is_true(ok)
    local b = decoded.bean or decoded[1] or decoded
    assert.are.equal("in-progress", b.status)
    assert.are.equal("bug", b.type)
    assert.are.equal("high", b.priority)
  end)

  it("does nothing on plain markdown outside a beans project", function()
    child = child_helper.spawn()
    if not child then
      pending("could not spawn a child Neovim")
      return
    end
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    local md = dir .. "/notes.md"
    vim.fn.writefile({ "# Notes", "", "just plain markdown" }, md)

    child.exec_lua("local p = select(1, ...) vim.cmd('edit ' .. vim.fn.fnameescape(p))", { md })
    vim.wait(200)

    assert.is_false(child.has_float(), "a float opened on non-bean markdown")
    assert.is_true(child.eval("vim.b.beans == nil"), "vim.b.beans should be nil")

    -- <leader>bw (space bw) must do nothing: no keymap, no float, no error.
    child.input(" bw")
    vim.wait(150)
    assert.is_false(child.has_float(), "<leader>bw did something on non-bean markdown")
  end)
end)
