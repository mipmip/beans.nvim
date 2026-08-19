---
# beans.nvim-k534
title: Plugin QA gates
status: completed
type: epic
priority: normal
created_at: 2026-08-19T21:20:28Z
updated_at: 2026-08-19T21:36:25Z
parent: beans.nvim-cesp
---

Neovim-plugin QA the huphop (Go) process didn't need:
- minimal-install smoke: load the plugin + setup() in a CLEAN nvim (no dev flake) — the
  gate that would have caught the setup() activation bug; wire into BOTH release.sh
  preflight AND ci.yml.
- luacheck (+ .luacheckrc) alongside stylua.
- doc/ helptags freshness check.

## Acceptance
- [ ] Minimal-install smoke passes in CI and in release preflight.
- [ ] luacheck clean; helptags in sync.

## Summary of Changes
Minimal-install smoke (scripts/smoke.sh): clean nvim, setup(), asserts commands +
detection + version — the guard for the setup() activation class. luacheck (+.luacheckrc,
0 warnings) and doc/ helptags freshness. All wired into ci.yml (smoke in the plain-nvim
job) and the release.sh preflight.
