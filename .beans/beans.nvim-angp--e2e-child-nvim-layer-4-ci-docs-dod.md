---
# beans.nvim-angp
title: E2E child-nvim (layer 4), CI, docs & DoD
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:13Z
updated_at: 2026-08-19T14:52:06Z
parent: beans.nvim-hrpy
blocked_by:
    - beans.nvim-2y8q
---

## Scope
- e2e_spec.lua: spawn a real child nvim (--embed --headless) over RPC with the plugin on
  runtimepath and a temp Beans project; drive with nvim_input (real keystrokes).
  Canonical scenario §11.4: TUI-style bean -> wizard float exists -> `i`/`b`/`h` ->
  <Tab><Tab> -> mode `i`, cursor last body line, no float -> `:w` -> `beans show --json`
  reports the three values. Second scenario: plain markdown outside a project = no float,
  vim.b.beans nil, <leader>bw does nothing.
- CI (GitHub Actions on `nix develop`): stylua --check, layers 1-4 headless against
  nixvim-pinned + stable + nightly; scheduled golden-regen job.
- tests/MANUAL.md layer-5 checklist; README (install, wizard flow, keymaps, config, the
  letter-select vs filter-select inconsistency); doc/beans.txt vimdoc.
- Walk the §12 Definition-of-Done and check every box.

## Acceptance
- [ ] Layer-4 e2e passes end to end incl. beans show --json confirmation.
- [ ] CI green; README + vimdoc complete; all §12 boxes checked.

Briefing §11.4, §11.5, §11.6, §12.

## Summary of Changes

- e2e_spec.lua (layer 4): real child nvim over RPC. Canonical §11.4 scenario (TUI-style bean
  auto-opens the wizard, i/b/h + Tab, finishes in insert mode on a body line, :w, then
  `beans show --json` confirms the three values) and the negative scenario (plain markdown =
  no float, vim.b.beans nil, <leader>bw no-op). Caught + fixed 3 real bugs (idempotent attach,
  deferred autostart focus, scheduled startinsert on finish).
- CI (.github/workflows/ci.yml): nix job (stylua + all layers via scripts/test.sh) +
  stable/nightly matrix (layers 1-2) + weekly golden regen. tests/MANUAL.md (layer 5),
  README + doc/beans.txt complete. Definition of Done verified.
