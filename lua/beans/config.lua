-- beans.config — defaults and merge.
--
-- The default table below is the complete recommended configuration from
-- beans-nvim-briefing.md §7.3; per the briefing it "doubles as the spec for
-- config.lua". `setup()` with no arguments must produce the intended
-- experience, so every value here is the recommended default.
--
-- Validate-on-setup (warn once, fall back per key, never error) is added in
-- Milestone 04 (`configuration`). This module already provides the defaults and
-- a deep merge so partial user tables override only the keys they set.

local M = {}

--- The complete default configuration (§7.3).
M.defaults = {
  --- Path to the beans binary. Absolute paths are honoured as-is.
  executable = "beans",

  --- Milliseconds before a CLI read is abandoned. Reads are prefetched and
  --- non-blocking, so this only guards against a hung process.
  timeout = 5000,

  detect = {
    by_path = true,
    by_content = true,
    max_lines = 5,
    ignore = {},
  },

  wizard = {
    fields = { "status", "type", "priority", "tags", "parent" },

    autostart = {
      enabled = true,
      max_age_seconds = 30,
      require_empty_body = true,
    },

    keys = {
      next = "<Tab>",
      prev = "<S-Tab>",
      select = "<CR>",
      finish = { "<Esc>", "q" },
      abort = "<C-c>",
      down = { "j", "<Down>", "<C-n>" },
      up = { "k", "<Up>", "<C-p>" },
      toggle = "<Space>",
      new = "n",
      clear = "x",
    },

    mnemonics = {},

    window = {
      border = "rounded",
      position = "cursor",
      max_width = 60,
      max_height = 12,
      progress = true,
      footer = true,
    },

    hints = true,

    flash = { enabled = true, duration_ms = 250 },

    finish = {
      insert = true,
      cursor = "body_end",
    },
  },

  fields = {
    priority = {
      allow_clear = true,
    },
    tags = {
      normalize = true,
      validate = true,
    },
    parent = {
      types = { "milestone", "epic", "feature" },
      sort = "type",
    },
  },

  write = {
    touch_updated_at = false,
    quote = "minimal",
  },

  completion = {
    omnifunc = true,
    blink = false,
    cmp = false,
  },

  keymaps = {
    enabled = true,
    wizard = "<leader>bw",
    menu = "<leader>bb",
    fields = {
      status = "<leader>bs",
      type = "<leader>bt",
      priority = "<leader>bp",
      tags = "<leader>bg",
      parent = "<leader>bP",
    },
  },

  hooks = {
    on_attach = nil,
    on_finish = nil,
  },

  notify = vim.log.levels.INFO,

  --- Used only when `beans update --help` cannot be parsed (§2.3).
  fallback = {
    status = { "in-progress", "todo", "draft", "completed", "scrapped" },
    type = { "milestone", "epic", "bug", "feature", "task" },
    priority = { "critical", "high", "normal", "low", "deferred" },
  },
}

--- Deep-merge user options over the defaults.
--- Uses "force" so partial user tables override only the keys they set.
--- @param opts table|nil
--- @return table
function M.merge(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
