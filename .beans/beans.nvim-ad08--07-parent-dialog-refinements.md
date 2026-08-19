---
# beans.nvim-ad08
title: 07 Parent dialog refinements
status: completed
type: milestone
priority: normal
created_at: 2026-08-19T20:31:20Z
updated_at: 2026-08-19T20:39:13Z
---

Goal: two wizard refinements. Tracked as OpenSpec change `refine-parent-dialog`.

## Features
- Clear selection indicator on the highlighted option (all cards).
- Parent value carries the parent's title as a trailing comment.

See explore session; beans-nvim-briefing.md §4.1, §5.2, §7.3.

## Summary of Changes
Selection indicator + parent title comment shipped. 10 spec files green (new: frontmatter
comment tests, wizard parent-comment tests, config title_comment default), stylua clean.
OpenSpec change refine-parent-dialog archived.
