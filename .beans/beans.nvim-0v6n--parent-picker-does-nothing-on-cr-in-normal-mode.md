---
# beans.nvim-0v6n
title: Parent picker does nothing on <CR> in normal mode
status: todo
type: bug
priority: normal
created_at: 2026-08-19T19:21:08Z
updated_at: 2026-08-19T19:21:08Z
parent: beans.nvim-untr
---

Via `:Bean parent` / `<leader>bP` the picker lists beans, but positioning the
cursor and pressing <CR> does nothing — the step only binds <CR> and navigation in
INSERT mode (relying on `startinsert`) and selects by an internal index rather than
the cursor line.

## Root cause
`parent.enter` binds selection/navigation only in insert mode and tracks `st.cursor`
moved via <C-n>/<C-p>; there is no normal-mode <CR> and no mapping from the buffer
cursor position to a candidate.

## Expected
The picker is operable in normal mode: move with j/k (and <C-n>/<C-p>), press <CR> to
select the candidate under the cursor; typing still filters. Nothing relies solely on
insert mode being entered.

## Acceptance
- [ ] Normal-mode j/k + <CR> selects the candidate under the cursor and sets parent.
- [ ] Works both in the wizard and via `:Bean parent` / `<leader>bP`.
- [ ] Layer-2 spec drives selection in normal mode (no insert-mode dependency).
