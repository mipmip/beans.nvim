---
# beans.nvim-hrpy
title: 05 Testing, E2E & Release Readiness
status: todo
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T13:13:12Z
blocked_by:
    - beans.nvim-7lvg
---

Goal: prove the PoC works. Five test layers, golden-file equivalence against the
real CLI, a full end-to-end run through a child Neovim, CI gating, and docs.

Tracked as OpenSpec change: `testing-e2e-release`.

## Epics
- Unit & wizard specs (layers 1-2) with fake-beans stub + helpers
- Golden-file equivalence against the real CLI (layer 3)
- E2E child-nvim (layer 4), CI, manual checklist, docs & DoD sign-off

## Exit criteria
- Layers 1-4 pass headless in CI; golden matrix byte-identical to `beans update`.
- The §11.4 canonical e2e closes the loop via `beans show --json`.
- Every §12 Definition-of-Done box is checked.

See briefing §11, §12.
