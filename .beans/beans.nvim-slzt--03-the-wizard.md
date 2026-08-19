---
# beans.nvim-slzt
title: 03 The Wizard
status: completed
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T14:17:30Z
blocked_by:
    - beans.nvim-diz4
---

Goal: the product itself (§1) — the near-cursor float that lets a user set
status/type/priority/tags/parent with single keystrokes and drop into the body in
insert mode, editing the buffer directly (never shelling out) with one undo step per
field.

Tracked as OpenSpec change: `build-wizard`.

## Epics
- Wizard core & UI (state machine, float, undo grouping, universal keys, autostart)
- Enum steps (status/type/priority with dynamic mnemonics)
- Tags & parent steps (multi-select + filter-as-you-type)

## Exit criteria
- Auto-start on a fresh TUI-created bean; `<Esc>` always an instant exit (§6.1).
- Three interaction modes work; back-nav restores picks; five undos restore original.
- No blocking prompt anywhere in the wizard path (§11.0).

See briefing §4, §5, §11.0.

## Summary of Changes

The wizard — the product — is working end to end in-process: three interaction modes,
buffer-only edits, one undo per field (five undos restore), <Esc> finishes from any step,
finish lands in the body. 69 unit+wizard specs green; no blocking prompts (grep-tested).
OpenSpec change build-wizard archived; specs synced.
