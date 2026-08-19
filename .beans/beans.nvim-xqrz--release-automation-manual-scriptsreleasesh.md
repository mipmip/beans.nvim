---
# beans.nvim-xqrz
title: Release automation (manual scripts/release.sh)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T21:20:28Z
updated_at: 2026-08-19T21:36:25Z
parent: beans.nvim-cesp
---

scripts/release.sh (gum): preflight gates -> gum choose major/minor/patch -> compute
next semver -> bump VERSION + roll CHANGELOG [Unreleased] into [next] -> jj commit + push
-> git tag vX.Y.Z + push -> gh release create vX.Y.Z with notes from CHANGELOG. Add gum
to the flake devShell. No release.yml (decision B).

## Acceptance
- [ ] release.sh bumps, tags, pushes, and cuts the GitHub release from CHANGELOG.
- [ ] Aborts cleanly if any preflight gate fails; gum in devShell.

## Summary of Changes
scripts/release.sh: gated preflight, gum major/minor/patch bump, VERSION + CHANGELOG roll,
jj commit + push, git tag via colocated git, gh release create from CHANGELOG (decision B,
no release.yml). gum added to the flake devShell. Dry-run verified the bump/roll logic
(and caught a gawk `next` reserved-word bug, fixed).
