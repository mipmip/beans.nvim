---
# beans.nvim-untr
title: 06 Parent field fixes
status: todo
type: milestone
created_at: 2026-08-19T19:21:08Z
updated_at: 2026-08-19T19:21:08Z
---

Goal: fix three defects in the wizard's `parent` step and the random-access parent
picker, and tighten the default candidate types.

Tracked as OpenSpec change: `fix-parent-field`.

## Bugs
- Parent step shows the previous step's tags instead of candidates (stale filter query).
- Parent picker (`:Bean parent` / `<leader>bP`) does nothing on <CR> (insert-mode-only).
- Parent candidate list should be milestones and epics only.

See beans-nvim-briefing.md §4.2 (parent), §7.3 fields.parent.
