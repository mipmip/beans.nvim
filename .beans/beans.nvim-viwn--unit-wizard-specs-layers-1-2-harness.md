---
# beans.nvim-viwn
title: Unit & wizard specs (layers 1-2) + harness
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:13Z
updated_at: 2026-08-19T14:52:06Z
parent: beans.nvim-hrpy
blocked_by:
    - beans.nvim-vpcl
---

## Scope (tests/)
- minimal_init.lua; fake-beans executable stub on PATH emitting canned --help + JSON;
  helpers/project.lua (temp Beans project) and helpers/child.lua (RPC child nvim).
- Layer 1 specs: frontmatter_spec, schema_spec, project_spec, detect_spec, config_spec
  (priority coverage order of §11.1).
- Layer 2 wizard_spec: sequencing, mnemonic apply+advance, <S-Tab> restore, unchanged
  <Tab>, <Esc> from every step, one-undo-per-field (5 apply / 5 undo == original),
  finish state, tags toggle/new, parent filter + self-exclusion.
- Grep-as-test: no vim.fn.input/getchar/confirm/ui.select in the wizard path.

## Acceptance
- [ ] Layers 1-2 pass headless via PlenaryBustedDirectory.

Briefing §11.1, §11.2, §11.0, §9 tests tree.

## Summary of Changes

- Layers 1-2 harness complete: minimal_init (nix + vendored-plenary CI paths), functional
  fake-beans stub, helpers/project.lua (real-CLI temp project) and helpers/child.lua (RPC
  child nvim). Unit + wizard specs cover frontmatter/schema/project/detect/config/wizard/
  actions/completion. Grep-as-test guards against blocking prompts. All green headless.
