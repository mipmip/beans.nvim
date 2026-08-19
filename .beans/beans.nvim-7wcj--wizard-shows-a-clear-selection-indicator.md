---
# beans.nvim-7wcj
title: Wizard shows a clear selection indicator
status: completed
type: feature
priority: normal
created_at: 2026-08-19T20:31:20Z
updated_at: 2026-08-19T20:39:13Z
parent: beans.nvim-ad08
---

The highlighted (cursor) option is only marked by the BeansWizardCurrent line
highlight (linked to CursorLine), which is too subtle in many colorschemes — users
can't tell which item is selected. Note this is distinct from the `active` marker
(●) that shows the value already set on the bean.

## Expected
- A caret glyph (e.g. `▸`) in a left gutter marks the current option on every card
  (enum, tags, parent).
- BeansWizardCurrent links to a selection-style group (PmenuSel) by default for
  stronger contrast; still overridable.

## Acceptance
- [ ] Current option shows a caret indicator distinct from the ● active marker.
- [ ] Default highlight is clearly visible across common colorschemes.

## Summary of Changes
ui.render adds a caret (▸) gutter marking the current option, distinct from the ● active
marker; byte-column math updated for the multibyte glyphs. BeansWizardCurrent now links
PmenuSel by default (was CursorLine). Applies to all cards; specs added.
