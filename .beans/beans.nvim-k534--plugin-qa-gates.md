---
# beans.nvim-k534
title: Plugin QA gates
status: todo
type: epic
priority: normal
created_at: 2026-08-19T21:20:28Z
updated_at: 2026-08-19T21:20:28Z
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
