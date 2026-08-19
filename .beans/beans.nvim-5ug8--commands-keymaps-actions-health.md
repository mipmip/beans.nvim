---
# beans.nvim-5ug8
title: Commands, keymaps, actions & health
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:13Z
parent: beans.nvim-7lvg
blocked_by:
    - beans.nvim-62q6
---

## Scope (init.lua, actions.lua, health.lua)
- Commands: `:BeanWizard`, `:Bean` (field menu -> value picker), `:Bean <field>` with
  field-name completion, `:checkhealth beans`.
- Random-access path (actions.lua): use the buffer-edit code path when the bean is open;
  fall back to `beans update` only for a bean not currently in a buffer. `vim.ui.select`
  allowed here (outside the wizard) but stubbable in tests.
- Buffer-local keymaps of §7.2, all disable-able / overridable; hooks on_attach/on_finish.
- Full checkhealth report (§6): binary+version, root, dir, recognised?/why, vocab, cache.

## Acceptance
- [ ] Commands + keymaps attach only in bean buffers.
- [ ] `:checkhealth beans` explains a detection failure.

Briefing §7.1, §7.2, §5.1, §6, §12.
