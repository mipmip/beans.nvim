## Why

beans.nvim has no release process (no `VERSION`, `CHANGELOG`, tags, or maintainer docs)
and is ready for a first alpha tag (`beans.nvim-cesp`). It also lacks a couple of QA gates
specific to a Neovim plugin — most importantly a **minimal-install smoke test**: the plugin
must load and `setup()` in a clean Neovim without the dev flake. We already shipped a bug
where the plugin was on `runtimepath` but never activated; that exact class of "works in
dev, broken for users" failure is what this gate guards.

This adapts the huphop `add-release-process` pattern (VERSION + CHANGELOG + gum-driven
release script + tag-triggered release), **dropping everything binary-specific** — a
Neovim plugin has no build artifact, so a release is simply a git tag. No goreleaser, no
`go:embed`, no `vendorHash`, no cross-compilation.

## What Changes

- Add a `VERSION` file (`0.1.0`) as the single source of truth, surfaced as
  `require("beans").version` and reported by `:checkhealth beans`.
- Add `CHANGELOG.md` (Keep a Changelog, with an `[Unreleased]` section) and `RELEASING.md`
  (maintainer docs, including the pre-1.0 semver note).
- Add `scripts/release.sh` (gum): preflight QA gates → `gum choose major/minor/patch` →
  bump `VERSION` and roll `[Unreleased]` into the new version section → `jj` commit + push
  → `git tag vX.Y.Z` + push → `gh release create` with notes from the CHANGELOG. Releases
  are cut **manually** by running the script; there is no `release.yml` workflow.
- Add `gum` to the flake devShell.
- Add plugin QA gates: a minimal-install smoke test (clean nvim, no flake), `luacheck`
  (+ `.luacheckrc`), and a `doc/` helptags freshness check — run both in `release.sh`
  preflight and as CI gates in `ci.yml`.

## Capabilities

### New Capabilities
- `version-management`: `VERSION` source of truth, `require("beans").version`, checkhealth
  reporting, and the `CHANGELOG`/`RELEASING` docs contract.
- `release-automation`: the manual, gated `scripts/release.sh` (gum bump → jj commit → git
  tag → `gh release create`) and `gum` in the devShell.
- `plugin-qa-gates`: minimal-install smoke test, luacheck, and helptags freshness, enforced
  in CI and in the release preflight.

### Modified Capabilities

## Impact

- New files: `VERSION`, `CHANGELOG.md`, `RELEASING.md`, `scripts/release.sh`,
  `.luacheckrc`, a minimal-install smoke spec/harness.
- Modified: `lua/beans/init.lua` (`M.version`), `lua/beans/health.lua` (report version),
  `flake.nix` (gum in devShell), `.github/workflows/ci.yml` (smoke + luacheck + helptags
  jobs).
- Dev dependency (devShell + local): `gum`, `luacheck`; `gh` used locally by `release.sh`.
- First release will be `v0.1.0`, cut by running `scripts/release.sh`.
