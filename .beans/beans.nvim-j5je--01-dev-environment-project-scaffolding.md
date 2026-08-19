---
# beans.nvim-j5je
title: 01 Dev Environment & Project Scaffolding
status: completed
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T13:37:06Z
---

Goal: `nix develop` yields a self-contained, isolated Neovim with the `beans`
binary available, and the repo skeleton (module layout, tooling, docs stubs) is in
place. Nothing here touches the developer's real config.

Tracked as OpenSpec change: `bootstrap-dev-environment`.

## Epics
- Nix flake dev environment (plain nix multi-system, no flake-utils)
- Repo scaffolding, module skeleton & tooling

## Exit criteria
- `nix develop` opens an isolated nvim with `beans` on PATH (briefing DoD).
- Module tree of §9 exists as stubs; `stylua --check` passes; `.dev/` gitignored.

See `beans-nvim-briefing.md` §9, §10.

## Summary of Changes

Dev environment and scaffolding complete. `nix develop` yields an isolated NixVim
with `beans` 0.4.2; the §9 module tree exists as loadable stubs; `stylua --check`
passes and the test suite runs green. OpenSpec change `bootstrap-dev-environment`
archived; specs `dev-environment` and `project-scaffolding` synced to openspec/specs/.
