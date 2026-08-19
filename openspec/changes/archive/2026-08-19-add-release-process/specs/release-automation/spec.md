## ADDED Requirements

### Requirement: Manual release script
The repository SHALL provide `scripts/release.sh` that cuts a release manually. It SHALL
prompt for the bump level with a `gum` chooser offering `major`, `minor`, and `patch`,
compute the next version from `VERSION` by semantic versioning, and require confirmation
before proceeding. `gum` SHALL be available in the flake devShell.

#### Scenario: Choosing a bump level computes the next version
- **WHEN** the maintainer runs `scripts/release.sh` and selects a bump level
- **THEN** the next version is computed from `VERSION` (`patch` → z+1, `minor` → y+1.0,
  `major` → x+1.0.0) and shown for confirmation

### Requirement: Release script bumps, tags, and publishes
On confirmation, `scripts/release.sh` SHALL update `VERSION`, roll the `[Unreleased]`
CHANGELOG section into a dated section for the new version (adding a fresh `[Unreleased]`),
commit and push with `jj`, create and push the `vX.Y.Z` git tag through the colocated git,
and create the GitHub release with `gh release create` using the new CHANGELOG section as
the notes. There SHALL be no GitHub Actions release workflow.

#### Scenario: A release is cut end to end
- **WHEN** the maintainer confirms the release
- **THEN** `VERSION` and `CHANGELOG.md` are updated, a `jj` commit is pushed, a `vX.Y.Z`
  tag is pushed via git, and a GitHub release is created from the CHANGELOG section

#### Scenario: The tag is pushed through git, not jj
- **WHEN** the release commit exists
- **THEN** the tag is created and pushed via the colocated git (`git tag` / `git push
  origin vX.Y.Z`), since `jj git push` does not push tags

### Requirement: Release preflight gates
`scripts/release.sh` SHALL abort before making any change unless all preflight gates pass:
a clean working copy on an up-to-date `main`, `nix flake check`, the full test suite
(`scripts/test.sh`), `stylua --check`, `luacheck`, the minimal-install smoke test, and a
docs/helptags freshness check.

#### Scenario: A failing gate aborts the release
- **WHEN** any preflight gate fails
- **THEN** the script exits non-zero without modifying `VERSION`, `CHANGELOG.md`, or
  creating a tag or release
