---
# beans.nvim-2y8q
title: Golden-file equivalence vs real CLI (layer 3)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:13Z
updated_at: 2026-08-19T14:52:06Z
parent: beans.nvim-hrpy
blocked_by:
    - beans.nvim-viwn
---

## Scope (golden_spec.lua, fixtures/golden/)
- Matrix (§11.3): set status/type/priority; clear priority; add 1/3 tags; remove a tag;
  remove all tags; set/clear parent; title-with-colon — each against a fully-populated
  and a minimal bean.
- In a temp `beans init` project: create bean, copy to A.md/B.md; apply via
  `beans update` to A and via frontmatter.lua to B; assert byte-identical modulo
  updated_at.
- Commit CLI outputs as golden files so the matrix also runs without a beans binary;
  add a job to regenerate goldens against the latest release (drift alarm).

## Acceptance
- [ ] Golden matrix byte-identical to `beans update` across every scenario.

Briefing §11.3, §12 (the acceptance test that matters most).

## Summary of Changes

- golden_spec.lua: §11.3 matrix (14 scenarios across minimal + full beans) applies each
  change via the real `beans update` and via frontmatter.lua and asserts equivalence —
  byte-identical modulo the Beans-owned updated_at line, with the tags block compared as a
  SET (beans emits tag order nondeterministically; Go map iteration). helpers/project.lua
  drives the real CLI. 10/10 consecutive runs green.
