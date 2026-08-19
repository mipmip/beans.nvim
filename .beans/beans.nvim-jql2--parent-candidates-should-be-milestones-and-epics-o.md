---
# beans.nvim-jql2
title: Parent candidates should be milestones and epics only
status: todo
type: bug
priority: normal
created_at: 2026-08-19T19:21:08Z
updated_at: 2026-08-19T19:21:08Z
parent: beans.nvim-untr
---

The default `fields.parent.types` includes `feature`, so features appear as parent
candidates. Only milestones and epics should be offered by default.

## Expected
Default `fields.parent.types = { "milestone", "epic" }`. Candidates of other types are
excluded unless the user overrides the config (nil = offer every type).

## Acceptance
- [ ] Default candidate list contains only milestones and epics; features excluded.
- [ ] Config override still honoured (custom list, or nil for all types).
- [ ] Spec + default table updated.
