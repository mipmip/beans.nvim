---
# beans.nvim-vpcl
title: Insert-mode completion (omnifunc + optional sources)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:13Z
updated_at: 2026-08-19T14:23:47Z
parent: beans.nvim-7lvg
blocked_by:
    - beans.nvim-5ug8
---

## Scope (completion.lua)
- Buffer-local omnifunc in bean buffers only; complete ONLY inside frontmatter after a
  known key: status/type/priority/parent values, or a tags: list item. Otherwise return
  nothing.
- Optional blink.cmp and nvim-cmp sources behind config flags, both default off, both
  lazily required (never hard deps).
- Do NOT add insert-mode <Tab>/<CR> mappings.

## Acceptance
- [ ] Completes only in the right frontmatter contexts; silent elsewhere.
- [ ] cmp/blink stay optional; absent plugins cause no error.

Briefing §8.

## Summary of Changes

- completion.lua: buffer-local omnifunc that completes ONLY inside frontmatter after a
  known key (status/type/priority/parent/tags item); values read synchronously from schema
  caches with fallback; silent elsewhere. Optional blink/cmp sources behind flags (default
  off, lazily required, absent plugin no-ops). No insert-mode <Tab>/<CR> maps.
  completion_spec: 9 specs green.
