## Why

Two refinements from using the wizard (`beans.nvim-ad08`):

1. You can't tell which option is selected — the highlighted row is marked only by
   `BeansWizardCurrent` (linked to `CursorLine`), which is invisibly subtle in many
   colorschemes, and is easily confused with the `●` *active* marker (the value already
   set on the bean) (`beans.nvim-7wcj`).
2. Right after setting a parent, the id alone (`parent: beans.nvim-slzt`) doesn't tell
   you *which* bean it is. Showing the title inline — `parent: beans.nvim-slzt # 03 The
   Wizard` — confirms the pick at a glance (`beans.nvim-y3rv`).

## What Changes

- Every wizard card marks the current option with a caret glyph (e.g. `▸`) in a left
  gutter, distinct from the `●` active marker; `BeansWizardCurrent` defaults to a
  selection-style group (`PmenuSel`) for stronger contrast.
- When the plugin sets `parent`, it appends the parent's title as a YAML inline comment
  when `fields.parent.title_comment` is enabled (default `true`). Beans strips the
  comment on its next rewrite; the plugin does not re-add it (that would fight Beans and
  churn `beans serve`).

## Capabilities

### New Capabilities

### Modified Capabilities
- `wizard-core`: the float marks the selected option with a clear indicator, and the
  selection highlight defaults to a selection-style group.
- `wizard-tags-parent`: selecting a parent writes the candidate's title as a trailing
  comment when enabled.
- `frontmatter-engine`: scalar set accepts an optional trailing comment (added only when
  requested, so byte-identity vs `beans update` is unaffected for callers that don't ask).
- `configuration`: `fields.parent.title_comment` defaults to `true`.

## Impact

- `lua/beans/wizard/ui.lua` — indicator gutter + highlight default.
- `lua/beans/frontmatter.lua` — optional `comment` argument to `set_scalar`.
- `lua/beans/wizard/steps/parent.lua` — pass the candidate title on select.
- `lua/beans/config.lua` — `fields.parent.title_comment` default.
- Tests: `wizard_spec.lua`, `frontmatter_spec.lua`, `config_spec.lua`.
- Docs: `beans-nvim-briefing.md` §12 DoD note (intentional parent-line divergence).

Out of scope (split to its own change, `beans.nvim-ipmb`): making `blocking`/`blocked_by`
editable and giving them per-item title comments.
