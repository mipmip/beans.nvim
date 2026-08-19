-- project_spec.lua — root detection and .beans.yml reading (Milestone 02).

local project = require("beans.project")

--- Create a throwaway directory tree; returns the temp root.
local function tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(contents)
  fd:close()
end

describe("beans.project", function()
  it("finds the root from a nested directory", function()
    local root = tmpdir()
    write(root .. "/.beans.yml", "beans:\n    path: .beans\n")
    vim.fn.mkdir(root .. "/.beans", "p")
    vim.fn.mkdir(root .. "/a/b/c", "p")

    assert.are.equal(vim.fs.normalize(root), project.find_root(root .. "/a/b/c"))
  end)

  it("reads a custom beans.path", function()
    local root = tmpdir()
    write(root .. "/.beans.yml", "beans:\n    path: issues\n    prefix: x-\n")
    assert.are.equal("issues", project.read_beans_path(root))
    assert.are.equal(vim.fs.normalize(root .. "/issues"), project.beans_dir(root))
  end)

  it("defaults beans.path to .beans when unset", function()
    local root = tmpdir()
    write(root .. "/.beans.yml", "other:\n    foo: bar\n")
    assert.are.equal(".beans", project.read_beans_path(root))
  end)

  it("falls back to a .beans/ directory when no .beans.yml exists", function()
    local root = tmpdir()
    vim.fn.mkdir(root .. "/.beans", "p")
    assert.are.equal(vim.fs.normalize(root), project.find_root(root .. "/.beans"))
  end)

  it("returns nil outside any beans project", function()
    local root = tmpdir()
    vim.fn.mkdir(root .. "/plain", "p")
    assert.is_nil(project.find_root(root .. "/plain"))
    assert.is_nil(project.locate(root .. "/plain/notes.md"))
  end)

  it("locate returns root and beans_dir together", function()
    local root = tmpdir()
    write(root .. "/.beans.yml", "beans:\n    path: .beans\n")
    vim.fn.mkdir(root .. "/.beans", "p")
    local located = project.locate(root .. "/.beans/x--y.md")
    assert.are.equal(vim.fs.normalize(root), located.root)
    assert.are.equal(vim.fs.normalize(root .. "/.beans"), located.beans_dir)
  end)
end)
