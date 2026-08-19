---
# beans.nvim-cqc9
title: Enum steps (status/type/priority)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T14:17:30Z
parent: beans.nvim-slzt
blocked_by:
    - beans.nvim-bsoh
---

## Scope (wizard/steps/enum.lua)
- Press-the-letter = select + confirm + auto-advance (one keystroke per field).
- Mnemonics computed dynamically from discovered vocab (never hardcoded).
- Show current value (BeansWizardActive) and hints (BeansWizardHint) beside options.
- priority supports a clear entry (allow_clear); status/type do not.

## Acceptance
- [ ] Mnemonic keypress applies value and advances (layer 2).
- [ ] <Tab> on unchanged field advances without dirtying the buffer.
- [ ] priority clear removes the line.

Briefing §4.2 (enum), §7.3 fields.priority.

## Summary of Changes

- `wizard/steps/enum.lua`: status/type/priority. Press-the-letter = select + confirm +
  auto-advance; mnemonics from discovered vocab (overrides honoured); shows active value
  + hints; priority clear entry when allow_clear. j/k/<CR>/<Tab> supported.
