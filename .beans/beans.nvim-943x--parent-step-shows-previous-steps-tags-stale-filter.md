---
# beans.nvim-943x
title: Parent step shows previous step's tags (stale filter query)
status: completed
type: bug
priority: normal
created_at: 2026-08-19T19:21:08Z
updated_at: 2026-08-19T19:36:37Z
parent: beans.nvim-untr
---

The `parent` step (last wizard step) renders the previous step's tag checkboxes
(e.g. `[ ] core`) on its prompt line instead of an empty filter, so the candidate
card looks wrong and filtering starts polluted.

## Root cause
`parent.enter`'s initial `draw()` sets the float prompt to `query()`, which reads
line 2 of the *float buffer* — still holding the prior tags render — instead of
starting from an empty query. (In a freshly opened float the line is blank, which
is why single-field `:Bean parent` looked fine but the full 5-step flow did not.)

## Expected
On entering the `parent` step the filter query starts empty and the card shows only
the candidate list (plus the clear entry); no content from the previous step remains.

## Acceptance
- [x] Full 5-step flow: the `parent` card shows only candidates + clear, prompt empty.
- [ ] Layer-2 spec covers tags→parent transition leaving no stale line.

## Summary of Changes
Query now lives in `state.parent.query` (default ""), rendered from state — never
seeded from the float buffer. Verified: full tags→parent flow shows no stale tag line.
