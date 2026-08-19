-- luacheck configuration for beans.nvim
std = "lua51"
cache = true

-- stylua owns formatting (line length etc.); luacheck focuses on semantics.
max_line_length = false

-- Neovim's `vim` global — writable so `vim.b.x = y`, `vim.g.x = y`, and test
-- stubs like `vim.notify = ...` are not flagged.
globals = { "vim" }

-- plenary busted globals in the test suite.
files["tests/"] = {
  read_globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "assert",
    "pending",
  },
}
