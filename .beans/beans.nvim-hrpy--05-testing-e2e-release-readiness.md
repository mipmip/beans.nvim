---
# beans.nvim-hrpy
title: 05 Testing, E2E & Release Readiness
status: completed
type: milestone
priority: normal
created_at: 2026-08-19T13:13:11Z
updated_at: 2026-08-19T14:52:06Z
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

## Summary of Changes

Testing, e2e and release readiness complete. 104 automated specs across 5 layers pass
deterministically headless; golden-file equivalence proves the buffer-editing decision is
safe; the canonical e2e closes the loop through the real CLI. CI green (nix + stable/nightly);
docs and manual checklist in place; every §12 Definition-of-Done item verified. OpenSpec
change testing-e2e-release archived.
