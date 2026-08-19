---
# beans.nvim-bsoh
title: Wizard core & UI (state machine, float, undo, keys)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T14:17:30Z
parent: beans.nvim-slzt
blocked_by:
    - beans.nvim-888o
---

## Scope (wizard/init.lua, wizard/ui.lua)
- Step sequencing from config `fields`; universal keys (§4.3): next/prev/select/
  finish(<Esc>/q)/abort(<C-c>). <Esc> finishes entirely; advancing past last step
  finishes. Finish: cursor to body per config, `startinsert` on empty body's first
  body line (not the closing `---`).
- Small float near cursor: title+progress `2/5 · type`, options, key footer. Move
  cursor to the field's line in the buffer and highlight; flash changed text.
- One undo step per applied field (single nvim_buf_set_lines via frontmatter.lua).
- Back-nav re-enters a step with the prior pick highlighted (<S-Tab> then <Tab> no-op).
- Autostart wiring (all of: recognised bean + created_at within max_age + empty body).
- NO blocking prompts anywhere (§11.0) — grep-as-test target.
- Highlight groups (§7.4), all linking to standard groups.

## Acceptance
- [ ] Sequencing, finish state (mode `i`, last body line), 5-undo restore.
- [ ] <Esc> exits from every step; float cleaned up (no leaked win/keymap).

Briefing §4.1, §4.3, §4.4, §5, §7.4, §11.0, §11.2.

## Summary of Changes

- `wizard/init.lua`: state machine over configured `fields`; one-undo-per-field via
  undo-break + single nvim_buf_set_lines; universal keys (back/finish/abort); finish
  positions cursor on a body line + startinsert; autostart wiring; async prefetch +
  refresh; :BeanWizard command.
- `wizard/ui.lua`: near-cursor float, data-driven render (title/progress/options/footer/
  prompt), BeansWizard* highlight groups (linked to standard groups), field-line
  highlight + flash.
- No blocking prompts anywhere (grep-as-test green).
