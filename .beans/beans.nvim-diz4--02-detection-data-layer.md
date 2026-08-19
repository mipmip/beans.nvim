---
# beans.nvim-diz4
title: 02 Detection & Data Layer
status: todo
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T13:13:11Z
blocked_by:
    - beans.nvim-j5je
---

Goal: reliably recognise bean buffers and read/mutate their frontmatter, with
zero footprint on non-bean markdown. This is the mechanical core the wizard sits on.

Tracked as OpenSpec change: `build-data-layer`.

## Epics
- Project root & bean detection
- CLI & schema layer (async reads, vocab discovery, prefetch, cache)
- Frontmatter engine (pure, canonical order, heavily tested)

## Exit criteria
- Bean buffers set `vim.b.beans`; plain markdown attaches nothing (§6, §11.1).
- `frontmatter.lua` handles scalar set/insert/clear and list set/clear in canonical
  order, byte-identically to `beans update` (§2.2, §5.2).

See briefing §2, §5, §6.
