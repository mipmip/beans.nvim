## Why

The wizard is the product (briefing §1). Everything in Milestones 01–02 exists to
serve the next ten seconds after the Beans TUI spawns `$EDITOR` on a freshly created
bean: let the user fix up `status`, `type`, `priority`, `tags` and `parent` with
single keystrokes, then drop into the body in insert mode. Creating a well-formed
bean must feel *faster and more pleasant* than skipping the metadata and fixing it
later. If the wizard stutters, fires on a normal markdown file, or is annoying to
escape, it has failed.

## What Changes

- A near-cursor floating wizard that walks the configured fields in order
  (`status`, `type`, `priority`, `tags`, `parent`), rendering a title with progress
  (`2/5 · type`), the options, and a key-hints footer.
- All mutations are **direct buffer edits** through `frontmatter.lua` — the wizard
  never shells out to `beans update` while the file is open (briefing §5). Each
  applied field is exactly one undo step.
- Three distinct interaction models unified in one flow (briefing §4.2): enums select
  by single keypress and auto-advance; tags accumulate then confirm; parent filters
  as you type.
- Auto-start on a bean that the TUI just created; `<Esc>` is always an instant exit.
- **No blocking prompts anywhere in the wizard path** (briefing §11.0) — no
  `vim.fn.input`/`getchar`/`confirm` and no `vim.ui.select`/`vim.ui.input`. The
  new-tag entry and the parent filter are editable prompt lines inside the wizard
  buffer, driven entirely by buffer-local keymaps, so the whole flow is testable with
  `nvim_feedkeys`.

## Capabilities

### New Capabilities

- `wizard-core`: the state machine, floating-window UI, universal keys, undo grouping,
  finish/`startinsert` behaviour, auto-start heuristic wiring, and highlight groups.
- `wizard-enum-steps`: the `status`/`type`/`priority` steps — dynamic mnemonics,
  press-a-letter to select-and-advance, and the priority "clear" entry.
- `wizard-tags-parent`: the `tags` multi-select (in-buffer new-tag prompt + validation)
  and the `parent` filter-as-you-type step (self-exclusion, clear).

## Impact

- New modules: `lua/beans/wizard/init.lua`, `lua/beans/wizard/ui.lua`,
  `lua/beans/wizard/steps/enum.lua`, `lua/beans/wizard/steps/tags.lua`,
  `lua/beans/wizard/steps/parent.lua`.
- Consumes Milestone 02: `frontmatter.lua` (buffer edits), `schema.lua` (vocab,
  mnemonics, tag universe, parent candidates), `detect.lua` (`vim.b.beans`).
- Adds `:BeanWizard` and the `<leader>bw` mapping (full command/keymap surface lands
  in Milestone 04).
- Adds `Beans*` highlight groups (briefing §7.4), each linking to a standard group.
- Test surface: layer-2 in-process wizard specs (briefing §11.2) plus a grep-as-test
  asserting no blocking prompt exists in the wizard path.
