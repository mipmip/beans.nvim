---
# beans.nvim-888o
title: Frontmatter engine (pure, canonical order)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:58:16Z
parent: beans.nvim-diz4
blocked_by:
    - beans.nvim-w3rq
---

## Scope (frontmatter.lua) — pure line-list in/out, unit-testable without a buffer.
- Locate frontmatter (line 1 `---` to next `---`); bail if not a bean.
- Preserve `# <id>` comment and other comments; never touch created_at/updated_at/order.
- Scalar set (replace, preserve indent, minimal quoting incl. titles with colons).
- Scalar clear (priority): remove the line.
- Scalar insert at canonical position (§2.2): title,status,type,priority,tags,
  created_at,updated_at,order,parent,blocking,blocked_by.
- List set/clear (tags): block sequence; match existing indentation, else verify Beans'
  emitted indent (§14.1). One `nvim_buf_set_lines` call per field (one undo step).
- Byte-identical no-op when setting a value to what it already was.

## Acceptance
- [ ] Every insert gap covered (type/priority/parent/tags-missing, title+status-only).
- [ ] Titles with colons/quotes/#/leading-trailing space handled.
- [ ] Golden equivalence hooks ready for layer 3.

Briefing §2.2, §5.2, §11.1(1), verify §14.1.

## Summary of Changes

- `frontmatter.lua`: pure line-list engine — `find_block`, `set_scalar` (replace or
  canonical-order insert), `clear_scalar`, `set_list`/`clear_list` (tags block seq),
  minimal quoting. Grounded against the real CLI: 4-space tag indent, Beans quoting
  styles; preserves `# <id>`/created_at/updated_at/order; byte-identical no-op.
- `frontmatter_spec.lua` (26 specs) covering every insert gap, clears, tag lists,
  tricky titles, and no-op. All green.
