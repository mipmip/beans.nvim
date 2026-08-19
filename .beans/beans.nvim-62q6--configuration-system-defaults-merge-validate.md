---
# beans.nvim-62q6
title: Configuration system (defaults, merge, validate)
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:12Z
parent: beans.nvim-7lvg
blocked_by:
    - beans.nvim-udyu
---

## Scope (config.lua)
- Full default table of §7.3 verbatim; `setup()` with no args = intended experience.
- Merge via vim.tbl_deep_extend("force", ...); partial tables must not wipe siblings.
- Validate on setup: report problems once via vim.notify, fall back per offending key;
  never error out of setup(); tolerate missing `beans` on PATH.
- Fallback vocab table wired to schema.lua.

## Acceptance
- [ ] No-arg setup yields full experience; partial merge keeps siblings.
- [ ] Invalid value warns once and falls back rather than erroring.

Briefing §7.3, §11.1 config coverage, §12.
