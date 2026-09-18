# beans.nvim

A Neovim companion for [Beans](https://github.com/hmans/beans), a CLI-based
flat-file issue tracker. When the Beans TUI opens a freshly created bean in your
`$EDITOR`, beans.nvim pops a small near-cursor wizard so you can set `status`,
`type`, `priority`, `tags` and `parent` with single keystrokes, then drops you
into the body in insert mode — no YAML by hand, no CLI round-trip.

The whole point is the next ten seconds after a bean is created: making a
well-formed bean should be *faster and more pleasant* than skipping the metadata
and fixing it later.

## Requirements

- Neovim 0.10+
- The [`beans`](https://github.com/hmans/beans) CLI on your `$PATH`

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "mipmip/beans.nvim", opts = {} }
```

Or manually:

```lua
require("beans").setup()
```

`setup()` with **no arguments** yields the full intended experience — you do not
need to configure anything.

## The wizard

Five steps, in order: `status` → `type` → `priority` → `tags` → `parent`.

It **auto-starts** when the current buffer is a freshly created bean (a
recognised bean whose `created_at` is within the last 30 seconds and whose body
is still empty) — i.e. exactly the bean the TUI just made. Otherwise start it
manually with `:BeanWizard` or `<leader>bw`.

All mutations are **direct buffer edits** (never a `beans update` subprocess while
the file is open), so each field change is a single native undo step: after the
wizard, `u` walks back through your picks one at a time.

### A deliberate inconsistency

The three kinds of field cannot share one interaction model, and pretending
otherwise is worse than being honest about it:

- **Enum steps (`status`, `type`, `priority`) — select by letter.** Each option
  has a mnemonic; pressing it is *both* selection and confirmation, and the
  wizard auto-advances. One keystroke per field. Mnemonics are computed from the
  vocabulary Beans reports, so they always match your Beans version.
- **`tags` — accumulate, then confirm.** A checkbox list: `j`/`k` to move,
  `<Space>` to toggle, `n` to add a new tag (validated against Beans' tag rules),
  `<CR>`/`<Tab>` to confirm and advance.
- **`parent` — type to filter.** The candidate list is long, so you filter by
  typing (fuzzy over `"<id> <title>"`); `<C-n>`/`<C-p>` move, `<CR>` selects,
  and a `(clear parent)` entry removes an existing parent.

So: **no-typing steps select by letter; typing steps select by filter.**

### Universal keys

| Key       | Action                                   |
| --------- | ---------------------------------------- |
| `<Tab>`   | accept the current value, advance        |
| `<S-Tab>` | go back one step                         |
| `<CR>`    | select the highlighted option, advance   |
| `<Esc>` / `q` | **finish the wizard entirely**       |

`<Esc>` finishes rather than stepping back — the common case is "defaults are
fine, let me write." Finishing (or advancing past the last step) drops the cursor
into the body in insert mode.

## Commands

| Command              | Behaviour                                   |
| -------------------- | ------------------------------------------- |
| `:BeanWizard`        | start the wizard at step 1                  |
| `:Bean`              | field menu, then value picker               |
| `:Bean <field>`      | jump straight to one field (tab-completes)  |
| `:checkhealth beans` | diagnostics (detection, vocab, cache)       |

## Default keymaps (bean buffers only)

| Key          | Action        |
| ------------ | ------------- |
| `<leader>bw` | start wizard  |
| `<leader>bb` | field menu    |
| `<leader>bs` / `bt` / `bp` | status / type / priority |
| `<leader>bg` | tags          |
| `<leader>bP` | parent        |

Non-bean markdown buffers get **zero** keymaps, autocmds, commands or popups.

## Configuration

The complete default table is documented in `:help beans-config`. A partial
table merges over the defaults (setting one keymap does not wipe the others),
and an invalid value warns once and falls back rather than erroring. Highlights:

```lua
require("beans").setup({
  wizard = {
    fields = { "status", "type", "priority", "tags", "parent" },
    autostart = { enabled = true, max_age_seconds = 30, require_empty_body = true },
  },
  completion = { omnifunc = true, blink = false, cmp = false },
  keymaps = { enabled = true },
})
```

### Field defaults

`status`, `type` and `priority` each take a `default`: the value the wizard
starts its cursor on when the bean has no value for that field.

```lua
require("beans").setup({
  fields = { priority = { default = "normal" } },
})
```

A default is cursor placement, not a write. Opening a step never touches the
buffer, so the wizard still writes only what you confirm:

| Key               | Effect                                        |
| ----------------- | --------------------------------------------- |
| `<CR>` or letter  | writes the value under the cursor, advances   |
| `<Tab>`           | advances, leaves the field unset              |

Accepting a default therefore costs one keystroke rather than none. That is the
point: opening the wizard stays free of side effects, so pressing `<Esc>`
straight away leaves a fresh bean exactly as Beans wrote it (see
[Notes](#notes)).

A default applies only to an absent or empty field. A field that already has a
value keeps it and the cursor starts there. A value the vocabulary does not know
counts as set too, so the cursor stays on the first option instead of hiding the
discrepancy.

`priority` is the field this matters for. Beans fills `status` and `type` from
`.beans.yml` when it creates a bean, but it has no `default_priority`, so a
fresh bean arrives with no priority and the step would otherwise open on the
first value in the vocabulary.

A configured value the project's vocabulary does not contain warns once per
project and is ignored. Vocabularies are discovered per project at runtime, so a
value can be right in one project and wrong in another.

`tags` and `parent` take no default. In those steps `<Tab>` confirms and writes
rather than skipping, so a preselected value would be written by the key that
means "I chose nothing".

## Insert-mode completion

An `omnifunc` is set (buffer-local) in bean buffers only, completing values when
the cursor is inside the frontmatter after a known key. Optional `blink.cmp` and
`nvim-cmp` sources are available behind `completion.blink` / `completion.cmp`
(both off by default, both lazily loaded).

## Development

```sh
nix develop      # isolated NixVim + the beans CLI; nothing touches your config
nvim             # start the isolated editor
# inside nvim: <Space>rt runs the test suite, <Space>rr reloads the plugin
```

See [`tests/MANUAL.md`](tests/MANUAL.md) for the manual smoke checklist.

## Notes

- The plugin makes **only the edit you asked for**. `beans update` normalises a
  bean on write (e.g. it injects `priority: normal` when a bean has no priority);
  beans.nvim does not replicate that default-injection, by design (§5.2). The
  layer-3 golden tests prove the plugin's output is byte-identical to
  `beans update` for the field(s) actually changed.

## License

See [LICENSE](LICENSE).
