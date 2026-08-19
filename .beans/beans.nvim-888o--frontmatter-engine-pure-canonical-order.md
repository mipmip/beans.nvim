---
# beans.nvim-888o
title: Frontmatter engine (pure, canonical order)
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:12Z
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
