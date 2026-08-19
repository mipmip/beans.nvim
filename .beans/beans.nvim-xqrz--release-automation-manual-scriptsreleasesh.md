---
# beans.nvim-xqrz
title: Release automation (manual scripts/release.sh)
status: in-progress
type: epic
priority: normal
created_at: 2026-08-19T21:20:28Z
updated_at: 2026-08-19T21:27:07Z
parent: beans.nvim-cesp
---

scripts/release.sh (gum): preflight gates -> gum choose major/minor/patch -> compute
next semver -> bump VERSION + roll CHANGELOG [Unreleased] into [next] -> jj commit + push
-> git tag vX.Y.Z + push -> gh release create vX.Y.Z with notes from CHANGELOG. Add gum
to the flake devShell. No release.yml (decision B).

## Acceptance
- [ ] release.sh bumps, tags, pushes, and cuts the GitHub release from CHANGELOG.
- [ ] Aborts cleanly if any preflight gate fails; gum in devShell.
