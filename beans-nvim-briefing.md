# beans.nvim — Implementation Briefing

A Neovim plugin for [Beans](https://github.com/hmans/beans), a CLI-based flat-file
issue tracker. This document is the complete design spec for a first lovable
version. It is written to be implemented autonomously.

---

## 1. The product in one paragraph

A user is in the Beans TUI. They hit a key to create a bean. Because `$EDITOR`
points at Neovim, the new bean file opens in nvim with `title` and `created_at`
already filled and the mandatory frontmatter keys set to project defaults. **The
job of beans.nvim is the next ten seconds:** let the user fix up `status`, `type`,
`priority`, `tags` and `parent` with single keystrokes, then drop them into the
body in insert mode. No modal picker to fight, no CLI round-trip, no typing YAML
by hand.

The success test is a feeling, not a feature list: creating a well-formed bean
should be *faster and more pleasant* than skipping the metadata and fixing it
later. If the wizard is annoying to escape, or stutters while it shells out, or
fires on a normal markdown file, it has failed.

---

## 2. Ground truth about Beans

All of this was verified by reading the upstream source at `github.com/hmans/beans`
(commit on `main`, ~Aug 2026). Re-verify anything marked ⚠ before relying on it.

### 2.1 File format

Beans live as markdown files with YAML frontmatter, in a `.beans/` directory at
the project root. Filenames are `<id>--<slug>.md`, e.g.
`beans-0ajg--beans-complete-command.md`. Archived beans go in `.beans/archive/`.

A real file looks exactly like this:

```markdown
---
# beans-0ajg
title: beans complete command
status: todo
type: task
priority: normal
created_at: 2025-12-27T21:44:04Z
updated_at: 2026-03-07T23:10:48Z
order: VV
parent: beans-mmyp
---

Add `beans complete <id> [--summary <text>]` command.
```

Note the `# beans-0ajg` comment on the first line inside the frontmatter — the ID
is **not** a YAML key. It is emitted by `Bean.Render()` and must be preserved
verbatim.

### 2.2 Canonical field order

From the `renderFrontMatter` struct in `pkg/bean/bean.go`. Any key the plugin
inserts must land in this order so the file still looks like something Beans
wrote:

```
title, status, type, priority, tags, created_at, updated_at, order, parent, blocking, blocked_by
```

Required (always present): `title`, `status`.
Optional (`omitempty` — may be absent from a fresh bean): `type`, `priority`,
`tags`, `created_at`, `updated_at`, `order`, `parent`, `blocking`, `blocked_by`.

**This is the single most important mechanical detail in the spec:** setting a
value is sometimes a line *replacement* and sometimes a line *insertion*.

### 2.3 Vocabularies

Hardcoded in `pkg/config/config.go`. The source comment states explicitly that
statuses and types are *not* user-configurable, despite `.beans.yml` existing.

| Field | Values (in source order) |
| --- | --- |
| `status` | `in-progress`, `todo`, `draft`, `completed`, `scrapped` |
| `type` | `milestone`, `epic`, `bug`, `feature`, `task` |
| `priority` | `critical`, `high`, `normal`, `low`, `deferred` |

`completed` and `scrapped` carry an `Archive: true` flag — beans in those states
get archived.

**Do not hardcode these.** Discover them at runtime by parsing `beans update --help`,
where Cobra prints them into the flag descriptions:

```
  -s, --status string     New status (in-progress, todo, draft, completed, scrapped)
  -t, --type string       New type (milestone, epic, bug, feature, task)
  -p, --priority string   New priority (critical, high, normal, low, deferred, or empty to clear)
```

Parsing rule, verified working: find the line matching `--<field>` followed by a
word boundary, capture the first parenthesised group, split on commas, trim, and
**discard any item containing whitespace** (this cleanly drops `or empty to clear`).
Fall back to the table above if parsing yields nothing.

Descriptions for each value are also in `config.go` and make good inline hints in
the picker; they are worth copying into the plugin as a static hint table (a
lookup miss is fine, hints are cosmetic).

### 2.4 `.beans.yml`

At the project root, written by `beans init`. The plugin only needs `beans.path`
(default `.beans`) to locate the bean directory. Also present but not needed for
v1: `beans.prefix`, `beans.id_length`, `beans.default_status`, `beans.default_type`,
`server.port`, `worktree.*`, `agent.*`.

A tiny hand-rolled reader for this one key is fine; do not add a YAML dependency.

### 2.5 CLI surface used

| Command | Use |
| --- | --- |
| `beans update --help` | vocabulary discovery |
| `beans list --json` | tag universe + parent/blocker candidates (flat JSON array of bean objects, no envelope) |
| `beans show <id> --json` | current state of one bean |
| `beans update <id> <flags>` | mutation — **not used during the wizard**, see §5 |

Relevant `beans list` filters: `--type` (repeatable), `--status`, `--tag`,
`--search`, `--quiet`, `--full`, `--sort`, `--ready`.
Relevant `beans update` flags: `--status`, `--type`, `--priority` (empty string
clears), `--title`, `--parent`, `--remove-parent`, `--tag`/`--remove-tag`
(repeatable), `--blocking`/`--remove-blocking`, `--blocked-by`/`--remove-blocked-by`,
`--if-match <etag>`.

All commands accept `--beans-path` to override the bean directory. Every command
should be invoked with `cwd` set to the project root.

---

## 3. Naming and repository

- Repo and plugin name: **`beans.nvim`**. No existing plugin claims it. (The
  nearest neighbour is `mweisshaupt1988/neobeans.vim`, an unrelated NetBeans
  colorscheme.)
- Lua module root: `beans` — so `require("beans").setup{}`.
- Command prefix: `:Bean`.
- Buffer variable: `vim.b.beans` (table) — see §6.
- Augroup: `beans.nvim`.
- Highlight groups: prefix `Beans` (`BeansWizardTitle`, `BeansWizardKey`,
  `BeansWizardCurrent`, `BeansWizardHint`, `BeansFlash`), each linking to a
  standard group by default so any colorscheme works.

Project management for this repo uses **openspec + beans**; follow the existing
Claude Code skill for that workflow. Track implementation work as beans in this
repo's own `.beans/`.

---

## 4. The wizard — core UX spec

### 4.1 Flow

Five steps, in this order:

1. `status` — enum
2. `type` — enum
3. `priority` — enum
4. `tags` — multi-select
5. `parent` — single select from a long list

Enums come first deliberately: they need no I/O and can render instantly, which
buys time for the `beans list --json` prefetch that steps 4 and 5 depend on.

The wizard renders as a small float near the cursor. It shows: a title line with
progress (`2/5 · type`), the options, and a footer with the active keys. As each
step activates, **move the cursor to that field's line in the buffer** (or where
the line will be inserted) and highlight it. When a value is applied, flash the
changed text briefly. The user must be able to see the document changing —
otherwise they're staring at a modal taking it on faith.

### 4.2 Three interaction modes, one flow

This is the hard part of the design. The three field kinds cannot share one
interaction model, and pretending otherwise produces something worse than
admitting it:

**Enum steps (status, type, priority) — press the letter, done.**
Each option gets a mnemonic key, and *the keypress is both selection and
confirmation*. One keystroke per field, then auto-advance. With the current
vocabularies the first letters are collision-free within each field
(`i/t/d/c/s`, `m/e/b/f/t`, `c/h/n/l/d`). **Compute mnemonics dynamically** from
the discovered vocabulary: try first letter, then next unused letter in the word,
then fall back to digits `1..9`. Never hardcode the mapping — vocabularies are
discovered, so they can change.

**Tags step — accumulate, then confirm.**
Multi-select cannot auto-advance on keypress. List all tags in the project with
`[x]`/`[ ]` checkboxes, `j`/`k` to move, `<Space>` to toggle, `n` to prompt for a
new tag, `<CR>` or `<Tab>` to confirm and advance. New tags must be normalised to
Beans' rules (lowercase, must match `^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$` — validate
and reject with a message rather than writing something the CLI would refuse).

**Parent step — type to filter.**
The candidate list can be long, so mnemonics are useless. Typing filters the list
(use `vim.fn.matchfuzzy` over `"<id> <title>"`), `<C-n>`/`<C-p>` or `j`/`k` move,
`<CR>` selects and advances, `x` clears an existing parent. Restrict candidates
to types `milestone`, `epic`, `feature` by default (configurable), and always
exclude the bean itself.

Document this inconsistency in the README rather than hiding it: no-typing steps
select by letter, typing steps select by filter.

### 4.3 Universal keys

Available in every step:

| Key | Action |
| --- | --- |
| `<Tab>` | accept current value, advance |
| `<S-Tab>` | go back one step |
| `<CR>` | select highlighted option, advance |
| `<Esc>` / `q` | **finish the wizard entirely** |
| `<C-c>` | same as `<Esc>` |

`<Esc>` finishing rather than stepping back is deliberate. Esc-as-back is
surprising, and the overwhelmingly common case is "defaults are fine, let me
write." Finishing (by `<Esc>`, or by advancing past the last step) places the
cursor at the end of the body and calls `startinsert`. That is the payoff moment
— make sure it lands cleanly on an empty body (cursor on the first body line, not
on the closing `---`).

Back-navigation re-enters a step with the value the user already picked
highlighted, so `<S-Tab>` then `<Tab>` is a no-op.

### 4.4 Undo

Each applied field change is **one undo step**. After the wizard, `u` walks back
through the picks one at a time, and the buffer returns to its as-opened state
after five undos. This is the main practical advantage of editing the buffer
directly and should be tested explicitly.

---

## 5. Editing strategy: buffer, not CLI

**During the wizard, all mutations are direct buffer edits.** Do not shell out to
`beans update` while the file is open in the editor.

Rationale:

- The TUI spawns `$EDITOR` on the **real file** (confirmed) and is blocked
  waiting for exit. A concurrent `beans update` rewrites the file underneath a
  possibly-modified buffer and forces a reconcile for no benefit.
- Per-field subprocess latency would wreck the "single keystroke" feel.
- Buffer edits give native undo for free.
- Nothing touches disk until `:w`, which is the contract the TUI expects.

The CLI remains the source of truth for **reads** (vocabulary, tag universe,
candidate beans), where latency is hidden by prefetching.

### 5.1 Consequences to handle

- `updated_at` will not be bumped by the plugin. ⚠ Verify what `beans serve`'s
  file watcher does when it sees the save — if it refreshes `updated_at`, nothing
  more is needed. If not, decide whether to set it in the buffer (ISO-8601 UTC,
  `2026-03-07T23:10:48Z` format) or leave it. Leaving it is acceptable for v1;
  the bean was just created.
- The plugin owns YAML serialization for the keys it writes. Keep this narrow:
  only scalars and one string-list format.
- The `:Bean <field>` random-access path (editing an *existing* bean, outside the
  wizard) may still use the CLI — but for v1, use the same buffer-edit code path
  when the bean is open in a buffer, and only fall back to `beans update` when
  acting on a bean that isn't currently open.

### 5.2 Frontmatter editing rules

Implement in a dedicated, well-tested module (`frontmatter.lua`) that operates on
a list of lines, so it is unit-testable without a live buffer.

- Locate the frontmatter: from a line 1 that is exactly `---` to the next `---`.
  If line 1 is not `---`, the buffer is not a bean — bail.
- Preserve the `# <id>` comment line and any other comment lines untouched.
- **Scalar set:** replace the value on the existing `^(\s*)<key>:\s*(.*)$` line,
  preserving indentation. Quote the value only if YAML requires it (contains `:`,
  `#`, leading/trailing space, or is a YAML-ambiguous word like `yes`/`no`/`null`).
  Titles from the TUI may legitimately contain colons — get this right.
- **Scalar clear** (priority): remove the line entirely rather than writing an
  empty value.
- **Scalar insert** (key absent): insert at the position dictated by the canonical
  order in §2.2, relative to the keys that *are* present.
- **List set** (tags): block sequence form. ⚠ Verify the exact indentation Beans
  emits by running `beans update <id> --tag foo` in a scratch project and reading
  the file — `yaml.v3` defaults to 4 spaces, but confirm. If a `tags:` block
  already exists, match its existing indentation instead of assuming.
- **List clear:** remove the key and all its items.
- **Never touch** `created_at`, `updated_at`, `order`, or the ID comment.
- Apply changes with `nvim_buf_set_lines` in a single call per field so each field
  is one undo step.

### 5.3 Prefetch and caching

On bean detection (`BufReadPost`), fire both reads asynchronously via
`vim.system`:

- `beans update --help` → vocabulary. Cache per project root for the session.
- `beans list --json` → tag universe + candidate beans. Cache per project root
  with a short TTL (~30s) and invalidate on `BufWritePost` of any bean.

If a step is reached before its data arrives, render a "loading…" state that
replaces itself when the data lands, rather than blocking. Never call
`vim.system():wait()` on the main loop.

---

## 6. Activation and detection

Two independent checks; **either one is sufficient**:

1. **Path** — walk up from the buffer for `.beans.yml` (fall back to a `.beans/`
   directory), read `beans.path`, and confirm the file lives under the resulting
   directory (including `archive/`).
2. **Content** — the first ~5 lines contain `---`, a `# <id>` comment, and a
   `title:` key. This is the safety net for any temp-file or worktree case where
   the path is uninformative.

Reading five lines of an already-loaded buffer costs nothing, so run both on
every markdown buffer.

**Mechanism:** on a positive match, set `vim.b.beans = { id = ..., root = ...,
beans_dir = ... }` and attach buffer-local keymaps.

**Do not** set a compound filetype like `markdown.beans`. It is tempting because
it gives free `ftplugin/` and `FileType` hooks, but many plugins compare
`filetype` with `==` rather than matching, and you will get sporadic reports of
LSP or treesitter failing to attach. A buffer variable is invisible to everything
that does not ask for it.

Non-bean markdown must see **zero** keymaps, commands-with-effects, autocmds, or
popups. This is a hard requirement.

Provide `:checkhealth beans` reporting: `beans` binary found and version, project
root detected, bean directory, whether the current buffer is recognised and why
not if it isn't, discovered vocabularies, and cache state. Detection failures are
the most likely support question; make them self-diagnosing.

### 6.1 Auto-start heuristic

The wizard auto-starts when **all** of:

- the buffer is a recognised bean, **and**
- `created_at` is within `autostart.max_age_seconds` (default 30) of now, **and**
- the body is empty or whitespace-only.

This reliably distinguishes "the TUI just made this" from "I opened an old bean,"
without process detection, and degrades gracefully in both directions. Config:
`autostart = { enabled = true, max_age_seconds = 30, require_empty_body = true }`.

Auto-opening a modal is delightful when correct and enraging when wrong, so it
must be one flag to disable, and `<Esc>` must always be an instant exit.

Manual entry: `:BeanWizard`, plus a keymap (default `<leader>bw`).

---

## 7. Commands, keymaps, config

### 7.1 Commands

| Command | Behaviour |
| --- | --- |
| `:BeanWizard` | start the wizard at step 1 |
| `:Bean` | field menu, then value picker (random access) |
| `:Bean <field>` | jump straight to one field; completes on field names |
| `:checkhealth beans` | diagnostics |

### 7.2 Default buffer-local keymaps (bean buffers only)

| Key | Action |
| --- | --- |
| `<leader>bw` | start wizard |
| `<leader>bb` | field menu |
| `<leader>bs` / `bt` / `bp` | status / type / priority |
| `<leader>bg` | tags |
| `<leader>bP` | parent |

All disable-able via `keymaps.enabled = false`; individual entries overridable.

### 7.3 Configuration

Design rules for the config surface:

- **`setup()` with no arguments must produce the intended experience.** Every
  default below is the recommended value; nobody should need to configure
  anything to get the product described in §1.
- Merge with `vim.tbl_deep_extend("force", …)`, so partial tables work — setting
  one keymap must not wipe the others.
- **Validate on setup** and report problems via `vim.notify` once, then fall back
  to the default for the offending key. Never error out of `setup()`; a
  misconfigured plugin should still load.
- Setup must not error when `beans` is missing from `$PATH` — degrade to a
  health-check warning.
- Anything a reasonable person would want to turn *off* gets a flag. Anything
  with one obviously-correct answer does not get an option.

This is the complete default table. It doubles as the spec for `config.lua`:

```lua
require("beans").setup({
  --- Path to the beans binary. Absolute paths are honoured as-is.
  executable = "beans",

  --- Milliseconds before a CLI read is abandoned. Reads are prefetched and
  --- non-blocking, so this only guards against a hung process.
  timeout = 5000,

  ---------------------------------------------------------------------------
  -- Detection: which buffers become bean buffers
  ---------------------------------------------------------------------------
  detect = {
    --- Match files living under the project's bean directory.
    by_path = true,
    --- Match files whose frontmatter carries a `# <id>` comment and a title.
    --- Safety net for worktrees and any temp-file case. Both checks are OR'd.
    by_content = true,
    --- How many leading lines the content check reads.
    max_lines = 5,
    --- Buffers matching these patterns are never treated as beans.
    ignore = {},
  },

  ---------------------------------------------------------------------------
  -- Wizard
  ---------------------------------------------------------------------------
  wizard = {
    --- Steps, in order. Remove entries to shorten the flow, reorder freely.
    --- Recognised: status, type, priority, tags, parent.
    --- Enums are cheapest and should stay first; see §4.1.
    fields = { "status", "type", "priority", "tags", "parent" },

    autostart = {
      enabled = true,
      --- A bean whose created_at is younger than this was almost certainly
      --- just made by the TUI. See §6.1.
      max_age_seconds = 30,
      --- Also require an empty body before auto-starting.
      require_empty_body = true,
    },

    --- Keys active inside the wizard float. Set any to false to unbind.
    keys = {
      next = "<Tab>",          -- accept current value, advance
      prev = "<S-Tab>",        -- back one step
      select = "<CR>",         -- choose highlighted option, advance
      finish = { "<Esc>", "q" },
      abort = "<C-c>",         -- finish without applying the current step
      down = { "j", "<Down>", "<C-n>" },
      up = { "k", "<Up>", "<C-p>" },
      toggle = "<Space>",      -- tags step
      new = "n",               -- tags step: add a tag not yet in the project
      clear = "x",             -- parent/priority step: unset the value
    },

    --- Override generated mnemonics per field, e.g. { status = { ["in-progress"] = "w" } }.
    --- Anything unlisted is assigned automatically (first free letter, then digits).
    mnemonics = {},

    window = {
      border = "rounded",
      --- "cursor" anchors near the field being edited; "center" is fixed.
      position = "cursor",
      max_width = 80,
      max_height = 16,
      --- Show "2/5 · type" in the title.
      progress = true,
      --- Show the key hints footer.
      footer = true,
    },

    --- Value descriptions from the Beans source, shown beside each option.
    hints = true,

    --- Briefly highlight a value in the document after it changes, so the user
    --- sees the file mutating rather than trusting the modal. See §4.1.
    flash = { enabled = true, duration_ms = 250 },

    finish = {
      --- Drop into insert mode in the body when the wizard ends.
      insert = true,
      --- "body_end" | "body_start" | "keep" (leave the cursor where it is).
      cursor = "body_end",
    },
  },

  ---------------------------------------------------------------------------
  -- Per-field behaviour
  ---------------------------------------------------------------------------
  fields = {
    priority = {
      --- Offer a "clear" entry. Priority is the only optional enum in the
      --- Beans schema (§2.2), so this is false for status and type by design.
      allow_clear = true,
    },
    tags = {
      --- Types offered as tag suggestions come from `beans list --json`.
      --- Lowercase and trim new tags before writing.
      normalize = true,
      --- Reject tags that fail Beans' own pattern rather than writing
      --- something the CLI would refuse. See §4.2.
      validate = true,
    },
    parent = {
      --- Candidate types. Set to nil to offer every bean.
      --- (Refined in change fix-parent-field: milestones and epics only.)
      types = { "milestone", "epic" },
      --- Sort candidates: "type" (milestone→epic→feature) | "recent" | "id".
      sort = "type",
    },
  },

  ---------------------------------------------------------------------------
  -- Writing
  ---------------------------------------------------------------------------
  write = {
    --- Set updated_at in the buffer when a field changes. Default false:
    --- Beans owns that field, and a freshly created bean doesn't need it.
    --- Flip to true only if §14.2 shows the watcher does not refresh it.
    touch_updated_at = false,
    --- Quote scalar values only when YAML requires it. Set "always" if a
    --- project prefers uniformly quoted strings.
    quote = "minimal",  -- "minimal" | "always"
  },

  ---------------------------------------------------------------------------
  -- Insert-mode completion (§8)
  ---------------------------------------------------------------------------
  completion = {
    --- Buffer-local omnifunc in bean buffers. Zero dependencies, no keymaps.
    omnifunc = true,
    --- Register sources for these, if installed. Lazily required.
    blink = false,
    cmp = false,
  },

  ---------------------------------------------------------------------------
  -- Keymaps (buffer-local, bean buffers only)
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Escape hatches
  ---------------------------------------------------------------------------
  --- Fired after detection and after the wizard closes. Both receive the
  --- bean context table ({ id, root, beans_dir, bufnr }); on_finish also
  --- receives a list of changed field names.
  hooks = {
    on_attach = nil,   -- fun(ctx)
    on_finish = nil,   -- fun(ctx, changed)
  },

  --- Minimum level passed to vim.notify, or false to silence the plugin.
  notify = vim.log.levels.INFO,

  ---------------------------------------------------------------------------
  -- Vocabularies (normally discovered; these are the safety net)
  ---------------------------------------------------------------------------
  --- Used only when `beans update --help` cannot be parsed (§2.3).
  fallback = {
    status = { "in-progress", "todo", "draft", "completed", "scrapped" },
    type = { "milestone", "epic", "bug", "feature", "task" },
    priority = { "critical", "high", "normal", "low", "deferred" },
  },
})
```

**Deliberately not configurable:** the canonical frontmatter field order (it is
Beans', not ours — §2.2); whether the wizard edits the buffer rather than
shelling out (§5); and the `# <id>` comment handling. Making any of these
optional would let a user produce files Beans does not round-trip cleanly.

### 7.4 Highlight groups

All default to `links`, so any colorscheme works untouched:

| Group | Links to | Used for |
| --- | --- | --- |
| `BeansWizardTitle` | `Title` | float title and progress |
| `BeansWizardKey` | `Special` | mnemonic letters |
| `BeansWizardCurrent` | `CursorLine` | highlighted option |
| `BeansWizardActive` | `DiagnosticOk` | the value currently set on the bean |
| `BeansWizardHint` | `Comment` | value descriptions |
| `BeansFieldLine` | `Visual` | the frontmatter line being edited |
| `BeansFlash` | `IncSearch` | post-change flash |

---

## 8. Insert-mode completion (opt-in)

Ship an `omnifunc` as the zero-dependency baseline: set `vim.bo.omnifunc`
buffer-locally in bean buffers only, and complete **only** when the cursor is
inside the frontmatter block, after a known key, on `status:`, `type:`,
`priority:`, `parent:` or a `tags:` list item. Outside those conditions, return
nothing and let the user's normal completion work.

Optionally register `blink.cmp` and `nvim-cmp` sources behind config flags, both
defaulting off, both lazily required so neither becomes a hard dependency.

**Do not add insert-mode `<Tab>` or `<CR>` mappings.** They will collide with
every completion plugin in existence. The wizard is modal by nature; the only
insert-mode moment that belongs to this plugin is `startinsert` at the end.

---

## 9. Module layout

```
beans.nvim/
├── flake.nix
├── flake.lock
├── .gitignore                 # .dev/
├── README.md
├── doc/beans.txt              # vimdoc, generated or hand-written
├── lua/beans/
│   ├── init.lua               # setup, autocmds, user commands
│   ├── config.lua             # defaults + merge
│   ├── health.lua             # :checkhealth beans
│   ├── project.lua            # root detection, .beans.yml reading
│   ├── detect.lua             # is-a-bean checks, sets vim.b.beans
│   ├── cli.lua                # async vim.system wrapper, JSON decode
│   ├── schema.lua             # field order, vocab discovery, prefetch, cache
│   ├── frontmatter.lua        # pure line-list parse/edit — heavily tested
│   ├── completion.lua         # omnifunc + optional cmp/blink sources
│   ├── wizard/
│   │   ├── init.lua           # state machine, step sequencing, undo grouping
│   │   ├── ui.lua             # float window, rendering, keymap wiring
│   │   └── steps/
│   │       ├── enum.lua       # status / type / priority
│   │       ├── tags.lua       # multi-select
│   │       └── parent.lua     # filter-as-you-type
│   └── actions.lua            # random-access :Bean <field> entry points
└── tests/
    ├── minimal_init.lua
    ├── MANUAL.md              # layer 5 smoke checklist
    ├── fixtures/
    │   ├── fake-beans         # executable stub emitting canned output
    │   ├── beans/…            # sample bean files + .beans.yml
    │   └── golden/…           # committed `beans update` outputs (layer 3)
    ├── helpers/
    │   ├── project.lua        # build a temp Beans project on disk
    │   └── child.lua          # spawn + drive a child nvim over RPC
    ├── frontmatter_spec.lua
    ├── schema_spec.lua
    ├── project_spec.lua
    ├── detect_spec.lua
    ├── config_spec.lua
    ├── wizard_spec.lua        # layer 2
    ├── golden_spec.lua        # layer 3
    └── e2e_spec.lua           # layer 4
```

No runtime dependencies. `plenary.nvim` is a test-only dependency.

---

## 10. Nix development environment

Provide a `flake.nix` closely modelled on
[`mipmip/vim-mimosa/flake.nix`](https://github.com/mipmip/vim-mimosa/blob/main/flake.nix),
which gives an isolated NixVim instance so development and testing never touch
the user's real config.

Required elements, mirroring that flake:

- Inputs: `nixpkgs` (nixos-unstable) and `nixvim` with `inputs.nixpkgs.follows`.
- Build the editor with `nixvim.legacyPackages.<system>.makeNixvimWithModule`.
- `extraPlugins`: `plenary-nvim`, `nvim-treesitter.withAllGrammars`.
- `extraConfigLua` that prepends the plugin source to `runtimepath` from an env
  var (`BEANS_NVIM_DEV_PATH`), falling back to the flake's own path.
- A `_G.reload_beans()` helper that clears `package.loaded` entries matching
  `^beans` and re-sources `plugin/` and `after/`, bound to `<leader>rr`.
- `<leader>rt` running `PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}`.
- `lua_ls` configured with `vim`, `describe`, `it`, `before_each`, `after_each`
  as known globals.
- `devShells.default` with the nvim package, `lua-language-server`, `stylua`.
- `shellHook` exporting `BEANS_NVIM_DEV_PATH="$(pwd)"` and redirecting
  `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` into
  `$(pwd)/.dev/…`, creating those directories, and printing a short help banner.
- `apps.default` pointing at the built nvim.

Additions specific to this project:

- Put the `beans` binary in the dev shell. ⚠ Check whether `beans` is packaged in
  nixpkgs; if not, add a `buildGoModule` derivation pinned to a release tag
  (module path `github.com/hmans/beans`). The env must be self-contained — a
  developer should get a working `beans` without installing anything.
- A scratch fixture project (`.dev/scratch/`) with `beans init` already run, so
  the real TUI → `$EDITOR` → nvim loop can be exercised end to end by hand.
- `.gitignore` must exclude `.dev/`.
- Add `stylua.toml` and run `stylua --check` in CI.

---

## 11. Testing

Five layers. Layers 1–4 are automated and gate CI; layer 5 is a short manual
checklist for the one thing that cannot reasonably be automated.

### 11.0 A design constraint that comes from testability

**Never use `vim.fn.input()`, `vim.fn.confirm()`, `vim.fn.getchar()`, or any
other blocking prompt anywhere in the wizard.** They halt the event loop and
cannot be driven by `nvim_feedkeys`, which would make the wizard untestable and
force the whole flow into manual QA.

Everything the user types goes through **buffer-local keymaps on a normal
(possibly floating) buffer**. The tags step's "new tag" entry and the parent
step's filter input must be implemented as an editable prompt line inside the
wizard buffer, not as a `vim.fn.input()` call. This is also better UX — the
prompt is themed, escapable with the same key as everything else, and does not
steal the command line.

Same rule for `vim.ui.select`/`vim.ui.input` inside the wizard: they route to
whatever picker the user installed, which is untestable and out of our control.
They remain fine for the random-access `:Bean <field>` path outside the wizard,
where test coverage can stub `vim.ui.select` directly.

### 11.1 Layer 1 — unit specs (fast, hermetic)

`plenary.nvim` busted-style specs. No real `beans` binary: an executable
`tests/fixtures/fake-beans` stub on `PATH` emits canned `--help` text and canned
JSON. Run via `<leader>rt` or
`nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"`.

Priority coverage, ordered by how much pain a bug there causes:

1. **`frontmatter.lua`** — replace an existing scalar; insert a missing scalar at
   the correct canonical position (test every gap: type-missing,
   priority-missing, parent-missing, tags-missing, and a bean with only
   `title`+`status`); clear a scalar; write and clear a tag list; preserve the
   `# id` comment, `created_at`, `updated_at`, `order`; handle titles containing
   colons, quotes, `#`, and leading/trailing space; leave the lines
   **byte-identical** when setting a value to what it already was.
2. **`schema.lua`** — help-text parsing including the `or empty to clear` tail;
   fallback when parsing fails or the binary is missing; mnemonic assignment,
   including a forced-collision vocabulary that must fall through to digits.
3. **`project.lua` / `detect.lua`** — root detection from nested dirs, custom
   `beans.path`, files in `archive/`, and the crucial negative: **a plain
   markdown file outside any Beans project attaches nothing** (assert
   `vim.b.beans == nil` and that no plugin keymap exists in the buffer).
4. **Auto-start heuristic** — fires on a fresh empty bean; does not fire on an
   old bean, a bean with a body, or when disabled.

### 11.2 Layer 2 — in-process wizard specs

Same harness, but driving the real wizard against a real buffer. Because §11.0
bans blocking prompts, `vim.api.nvim_feedkeys(keys, "x", false)` executes
synchronously and the assertions can run immediately after.

Cover: step sequencing; mnemonic keypress applies the value and advances;
`<S-Tab>` returns with the previous pick highlighted; `<Tab>` on an unchanged
field advances without dirtying the buffer; `<Esc>` exits from every step;
one-undo-step-per-field (apply five fields, press `u` five times, assert the
buffer matches the original exactly); finish state leaves the cursor on the last
body line in insert mode; tags toggle/new-tag; parent filter narrowing and
self-exclusion.

### 11.3 Layer 3 — golden-file equivalence against the real CLI

**This is the acceptance test that matters most**, because it is the one that
proves the buffer-editing decision was safe.

Skipped unless a real `beans` binary is present. For each scenario in a matrix —
set status; set type; set priority; clear priority; add one tag; add three tags;
remove a tag; remove all tags; set parent; clear parent; set a title containing a
colon; and each of those against both a fully-populated bean and a minimal one —
do the following in a temp project created with `beans init`:

1. Create a bean, copy the file to `A.md` and `B.md`.
2. Apply the change to `A` via `beans update <id> …`.
3. Apply the same change to `B` through the plugin's `frontmatter.lua`.
4. Assert the two files are **byte-identical** apart from `updated_at`.

Store the CLI outputs as committed golden files so the matrix also runs without
a `beans` binary, and add a CI job that regenerates them against the latest
release to catch upstream format drift. A failure here is the early warning that
Beans changed its schema.

### 11.4 Layer 4 — end-to-end through a child Neovim

Spawns a real, separate Neovim over RPC (`vim.fn.jobstart({ nvim, "--embed",
"--headless" }, { rpc = true })`, or `vim.rpcstart`) with the plugin on
`runtimepath` and a temp Beans project on disk. Drives it with `nvim_input` —
actual terminal-style keystrokes, not `feedkeys` — and asserts on what the child
reports back.

This is the layer that catches what unit tests structurally cannot: keymaps that
never got attached, a float that failed to open, an autocmd that fired twice, a
mapping that leaked into the parent buffer, mode-state bugs at finish.

The canonical scenario, which is the product in §1:

1. Write a bean file exactly as the TUI would (title + `created_at` = now +
   defaults + empty body).
2. Open it in the child nvim.
3. Assert the wizard float exists (`nvim_list_wins` has a window whose config
   `relative ~= ""`).
4. Send `i` `b` `h` — status `in-progress`, type `bug`, priority `high`.
5. Send `<Tab>` `<Tab>` to skip tags and parent.
6. Assert: mode is `i`, the cursor is on the last body line, no float remains.
7. Send `<Esc>` `:w<CR>`, then assert the file on disk parses and that
   `beans show <id> --json` reports the three chosen values.

That last step closes the loop through the real CLI: the plugin wrote it, Beans
read it back.

Second e2e scenario, equally important: open a plain markdown file **outside**
any Beans project, assert no float appears, `vim.b.beans` is nil, and
`<leader>bw` does nothing.

### 11.5 Layer 5 — manual smoke checklist

The Bubbletea TUI is not worth automating. Keep a short checklist in
`tests/MANUAL.md`, to be run in the flake's scratch project (§10) before each
release:

- [ ] From `beans tui`, create a bean; nvim opens with the wizard already up.
- [ ] Complete all five steps by keyboard only; no mouse, no command line.
- [ ] `:wq`; the TUI shows the bean with the chosen values.
- [ ] Repeat, pressing `<Esc>` immediately; the bean keeps its defaults and is
      still valid.
- [ ] Repeat inside a git worktree, where the bean directory is the worktree's
      own `.beans/`.
- [ ] With `beans serve` running, confirm the web UI reflects the save.

### 11.6 CI

GitHub Actions on `nix develop`: `stylua --check`, layers 1–4 headless, and the
golden-file regeneration job on a schedule. Test against the nixvim-pinned
Neovim plus stable and nightly, since floating-window and `vim.system` behaviour
are the parts most likely to drift.

---

## 12. Definition of done for v1

- [ ] Opening a bean created by the Beans TUI auto-starts the wizard.
- [ ] `status`, `type`, `priority` each set with one keystroke, auto-advancing.
- [ ] Tags multi-select with toggle, new-tag entry, and validation.
- [ ] Parent selection filtered by typing, self excluded, clearable.
- [ ] `<S-Tab>` goes back; `<Esc>` finishes from any step.
- [ ] Finishing leaves the cursor in the body in insert mode.
- [ ] Each field change is one undo step; five undos restore the original file.
- [ ] Missing optional keys are inserted in canonical order.
- [ ] Saving produces a file byte-identical to what `beans update` would have
      produced for the same values (⚠ verify by diffing against real CLI output —
      this is the acceptance test that matters most). Exception (change
      `refine-parent-dialog`): when `fields.parent.title_comment` is enabled the plugin
      appends the parent's title as a trailing YAML comment (`parent: <id> # <title>`),
      which `beans update` does not write. This is intentional and transient (Beans
      drops the comment on its next rewrite); the layer-3 golden test still passes
      because it exercises the engine without requesting a comment.
- [ ] A plain markdown file outside a Beans project gets no keymaps, no autocmds,
      no popups.
- [ ] `:checkhealth beans` explains any detection failure.
- [ ] `setup()` with no arguments yields the full intended experience; a partial
      config table merges without wiping sibling defaults; an invalid value warns
      once and falls back rather than erroring.
- [ ] No blocking prompt (`vim.fn.input`, `getchar`, `confirm`) exists anywhere
      in the wizard path — grep for them as a test.
- [ ] The layer-3 golden matrix passes: plugin output is byte-identical to
      `beans update` output across every scenario.
- [ ] The layer-4 e2e scenario passes end to end, including `beans show --json`
      confirming what the plugin wrote.
- [ ] `nix develop` gives a working isolated nvim with `beans` available; tests
      pass headless in CI.
- [ ] README covers install, the wizard flow, keymaps, config, and the deliberate
      inconsistency between letter-select and filter-select steps.

---

## 13. Explicit non-goals for v1

Deferred, and worth *not* half-building: a bean browser or picker over all beans
(the TUI already does this well); creating beans from within nvim; a statusline
component; GraphQL/WebSocket integration with `beans serve` for live updates;
`--if-match` etag concurrency handling; archive browsing; roadmap generation.

Keep the surface small enough that the wizard is unambiguously the product.

---

## 14. Verify before/while building

1. Exact indentation Beans emits for a `tags:` block sequence.
2. Whether `beans serve`'s watcher refreshes `updated_at` on an external write.
3. Whether `beans` is in nixpkgs, or needs a `buildGoModule` derivation.
4. Current output of `beans update --help` against the parsing rule in §2.3.
5. Whether `beans show <id> --json` returns an object or a single-element array.
6. That the TUI's editor invocation opens the real file path (expected: yes) and
   what it does with the file after nvim exits.
