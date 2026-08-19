---
# beans.nvim-ipmb
title: Editable blocking/blocked_by relationship fields
status: draft
type: feature
created_at: 2026-08-19T20:31:20Z
updated_at: 2026-08-19T20:31:20Z
---

Not implemented today: the plugin cannot edit `blocking`/`blocked_by` (no wizard
step, no :Bean action, not in default fields). They exist only in frontmatter.lua's
canonical-order list so they are preserved/placed if already present.

## Scope (future change: add-relationship-fields)
- Two new multi-select steps / :Bean actions for `blocking` and `blocked_by`,
  resolving candidate ids like the parent step (candidates from `beans list --json`,
  self-excluded).
- Per-ITEM title comments on the block sequence (different from parent's scalar
  trailing comment): `set_list` gains per-item comment support, e.g.
  `    - beans.nvim-abcd # 02 Detection`.
- Config: `fields.blocking.title_comment` / `fields.blocked_by.title_comment`.
- Add to doc/beans.txt + README once shipped.

## Notes
Split out from refine-parent-dialog (explore session): this is a new capability, not a
parent-dialog refinement. Frontmatter placement is already half-done via canonical order.
