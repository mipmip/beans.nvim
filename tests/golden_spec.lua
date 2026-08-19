-- golden_spec.lua — layer 3: byte-for-byte equivalence between the plugin's
-- frontmatter edits and what the real `beans update` CLI produces (§11.3).
--
-- This is the acceptance test that proves the buffer-editing decision (§5) is
-- safe. Skipped (pending) when the beans binary is not on $PATH.

local frontmatter = require("beans.frontmatter")

if vim.fn.executable("beans") == 0 then
  describe("golden equivalence", function()
    pending("beans binary not on $PATH — layer-3 matrix skipped")
  end)
  return
end

local project = dofile(vim.fn.getcwd() .. "/tests/helpers/project.lua")

--- Normalise a bean for comparison:
---   * drop the Beans-owned `updated_at:` line, and
---   * sort the items inside a `tags:` block.
--- The tag sort is required because `beans` does NOT emit tags in a stable order
--- (verified: `beans update --tag a --tag b --tag c` yields `a,b,c` most runs but
--- occasionally `b,c,a` — Go map iteration). Tags are semantically a set, so
--- layer 3 proves set-equality for the tag block and byte-identity everywhere
--- else. The plugin itself writes tags in a deterministic (given) order.
local function normalize(lines)
  local out, i, n = {}, 1, #lines
  while i <= n do
    local l = lines[i]
    if l:match("^%s*updated_at:") then
      i = i + 1
    elseif l:match("^%s*tags:%s*$") then
      out[#out + 1] = l
      local items, j = {}, i + 1
      while j <= n and lines[j]:match("^%s*%-%s+") do
        items[#items + 1] = lines[j]
        j = j + 1
      end
      table.sort(items)
      for _, it in ipairs(items) do
        out[#out + 1] = it
      end
      i = j
    else
      out[#out + 1] = l
      i = i + 1
    end
  end
  return out
end

--- Current tags on a bean (block-sequence form).
local function current_tags(lines)
  local out, in_block = {}, false
  for _, l in ipairs(lines) do
    if l:match("^%s*tags:%s*$") then
      in_block = true
    elseif in_block then
      local item = l:match("^%s*-%s+(.+)%s*$")
      if item then
        out[#out + 1] = (item:gsub("['\"]", ""))
      else
        in_block = false
      end
    end
  end
  return out
end

describe("golden equivalence", function()
  local root, parent_id

  before_each(function()
    root = project.create()
    parent_id = project.create_bean(root, "A parent", { "-t", "epic", "-s", "todo" }).id
  end)

  -- Create a bean, apply `cli_args` via the real CLI to get side A, apply
  -- `fm_fn(original_lines)` for side B, and assert byte-identical (sans updated_at).
  local function check(create_flags, cli_args, fm_fn)
    local bean = project.create_bean(root, "Sample bean", create_flags)
    local original = project.read(bean.path)

    local code = project.update(root, bean.id, cli_args)
    assert.are.equal(0, code, "beans update failed")
    local a = project.read(bean.path)

    local b = fm_fn(original)

    assert.are.same(normalize(a), normalize(b))
  end

  -- NOTE: `beans update` normalizes a bean by injecting `priority: normal` when
  -- the bean has none, whereas the plugin makes only the requested edit (§5.2).
  -- To isolate the serialization/ordering/quoting equivalence that layer 3 must
  -- prove, matrix beans already carry a priority — except the dedicated
  -- priority-insert case below (where both sides add it).
  local FULL = { "-t", "task", "-s", "todo", "-p", "normal", "--tag", "keep" }
  local MIN = { "-s", "todo", "-p", "normal" }
  local NO_PRIORITY = { "-s", "todo" }

  describe("scalar set", function()
    it("sets status (full)", function()
      check(FULL, { "--status", "in-progress" }, function(l)
        return (frontmatter.set_scalar(l, "status", "in-progress"))
      end)
    end)
    it("sets status (minimal)", function()
      check(MIN, { "--status", "draft" }, function(l)
        return (frontmatter.set_scalar(l, "status", "draft"))
      end)
    end)
    it("sets type (minimal)", function()
      check(MIN, { "--type", "bug" }, function(l)
        return (frontmatter.set_scalar(l, "type", "bug"))
      end)
    end)
    it("sets priority — insert into a bean without one", function()
      check(NO_PRIORITY, { "--priority", "high" }, function(l)
        return (frontmatter.set_scalar(l, "priority", "high"))
      end)
    end)
    it("sets priority — replace an existing one (full)", function()
      check(FULL, { "--priority", "low" }, function(l)
        return (frontmatter.set_scalar(l, "priority", "low"))
      end)
    end)
    it("sets a title containing a colon (full)", function()
      check(FULL, { "--title", "Fix: the thing" }, function(l)
        return (frontmatter.set_scalar(l, "title", "Fix: the thing"))
      end)
    end)
  end)

  describe("scalar clear", function()
    it("clears priority (full)", function()
      check(FULL, { "--priority", "" }, function(l)
        return (frontmatter.clear_scalar(l, "priority"))
      end)
    end)
  end)

  describe("parent", function()
    it("sets parent — insert (minimal)", function()
      check(MIN, { "--parent", parent_id }, function(l)
        return (frontmatter.set_scalar(l, "parent", parent_id))
      end)
    end)
    it("clears parent (parented bean)", function()
      check(
        { "-s", "todo", "-p", "normal", "--parent", parent_id },
        { "--remove-parent" },
        function(l)
          return (frontmatter.clear_scalar(l, "parent"))
        end
      )
    end)
  end)

  describe("tags", function()
    it("adds one tag to a bean without tags (minimal)", function()
      check(MIN, { "--tag", "alpha" }, function(l)
        return (frontmatter.set_list(l, "tags", { "alpha" }))
      end)
    end)
    it("adds three tags (minimal)", function()
      check(MIN, { "--tag", "a", "--tag", "b", "--tag", "c" }, function(l)
        return (frontmatter.set_list(l, "tags", { "a", "b", "c" }))
      end)
    end)
    it("appends a tag to an existing block (full)", function()
      check(FULL, { "--tag", "extra" }, function(l)
        local tags = current_tags(l)
        tags[#tags + 1] = "extra"
        return (frontmatter.set_list(l, "tags", tags))
      end)
    end)
    it("removes one tag (full)", function()
      check(FULL, { "--remove-tag", "keep" }, function(l)
        return (frontmatter.set_list(l, "tags", {}))
      end)
    end)
    it("removes all tags (bean with two)", function()
      check(
        { "-s", "todo", "-p", "normal", "--tag", "one", "--tag", "two" },
        { "--remove-tag", "one", "--remove-tag", "two" },
        function(l)
          return (frontmatter.clear_list(l, "tags"))
        end
      )
    end)
  end)
end)
