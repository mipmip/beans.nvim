---
# beans.nvim-7lvg
title: 04 Config, Commands & Completion
status: completed
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T14:23:47Z
blocked_by:
    - beans.nvim-slzt
---

Goal: the surface a user configures and drives — a zero-arg `setup()` that yields
the full experience, commands, buffer-local keymaps, and opt-in insert-mode completion.

Tracked as OpenSpec change: `config-commands-completion`.

## Epics
- Configuration system (defaults, deep merge, validate-and-warn)
- Commands, keymaps & actions (:BeanWizard, :Bean, :Bean <field>, hooks, health)
- Insert-mode completion (omnifunc baseline + optional cmp/blink sources)

## Exit criteria
- `setup()` with no args gives the intended experience; partial tables merge; invalid
  values warn once and fall back (§7.3).
- `:checkhealth beans` self-diagnoses detection failures (§6).

See briefing §6, §7, §8.

## Summary of Changes

Config surface, commands, keymaps, actions, health, and opt-in completion complete.
Zero-arg setup yields the full experience; invalid values warn once and fall back.
88 specs green; stylua clean. OpenSpec change config-commands-completion archived.
