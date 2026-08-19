---
# beans.nvim-udyu
title: Tags & parent steps
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:12Z
parent: beans.nvim-slzt
blocked_by:
    - beans.nvim-cqc9
---

## Scope (wizard/steps/tags.lua, wizard/steps/parent.lua)
- Tags: checkboxes over the project tag universe; j/k move, <Space> toggle, `n` opens
  an in-buffer editable prompt line (NOT vim.fn.input) to add a tag, <CR>/<Tab>
  confirm+advance. Normalise + validate new tags against
  `^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$`; reject with a message.
- Parent: filter-as-you-type via vim.fn.matchfuzzy over "<id> <title>"; <C-n>/<C-p> or
  j/k move, <CR> selects+advances, `x` clears. Candidates restricted to
  milestone/epic/feature (configurable); always exclude the bean itself. Sort per config.

## Acceptance
- [ ] Tag toggle + new-tag entry + validation reject path (layer 2).
- [ ] Parent filter narrowing + self-exclusion + clear.

Briefing §4.2 (tags, parent), §7.3 fields.tags/parent, §11.0.
