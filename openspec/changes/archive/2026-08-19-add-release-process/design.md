## Context

Explored against the huphop `add-release-process` change (a Go binary: goreleaser,
`go:embed`, `vendorHash`, cross-compiled artifacts, tag-triggered `release.yml`). beans.nvim
is a pure-Lua Neovim plugin distributed by git tag and consumed by plugin managers
(lazy.nvim, packer, mini.deps, …). Confirmed current state: no `VERSION`, `CHANGELOG`,
`RELEASING`, luacheck, release workflow, or tags — only `ci.yml`, `scripts/test.sh`, and a
hand-written `doc/beans.txt`.

## Goals / Non-Goals

**Goals:**
- One repeatable, manual command to cut a release, with QA gates that must pass first.
- Version legible in-repo and via `:checkhealth` for bug reports.
- Guard the "works in dev, broken for users" failure class permanently.

**Non-Goals:**
- Any build/compile step, goreleaser, `go:embed`, `vendorHash` (no binary).
- luarocks/rockspec publishing (tag-only distribution for now; future).
- A `release.yml` GitHub Actions workflow (the script cuts the release directly).
- Editing relationship fields, or any plugin behaviour change beyond exposing the version.

## Decisions

- **A release is a git tag.** Distribution is via managers cloning a tag; there is nothing
  to build or upload. `scripts/release.sh` is the whole mechanism.

- **Manual, gum-driven bump (decision from explore).** The script runs `gum choose
  major/minor/patch`, computes the next semver from `VERSION`, confirms, then bumps. No
  automated-on-merge releasing.

- **The script cuts the GitHub release directly (decision B).** After the jj commit and
  `git tag`, `release.sh` runs `gh release create vX.Y.Z` with notes extracted from the
  new `CHANGELOG` section. No `release.yml` — one file, fully manual, needs local `gh` auth.

- **Tags go through the colocated git.** `jj git push` does not push tags, so the script
  does `git tag vX.Y.Z <rev> && git push origin vX.Y.Z` after `jj commit` / `jj git push`.

- **Version source of truth = `VERSION` file**, read into `require("beans").version` and
  shown by `:checkhealth beans`. First value `0.1.0`.

- **Pre-1.0 semver note in RELEASING.md.** The dropdown maps literally
  (`patch 0.1.0→0.1.1`, `minor →0.2.0`, `major →1.0.0`), but before 1.0 breaking changes
  conventionally ride a **minor** bump and `major` is the deliberate "go stable → 1.0.0"
  choice.

- **Preflight gates == QA.** `release.sh` aborts unless, in order: working copy clean and on
  `main` up to date; `nix flake check`; `scripts/test.sh tests/` (all layers); `stylua
  --check`; `luacheck`; the minimal-install smoke; and helptags in sync.

- **Minimal-install smoke is also a permanent CI gate.** Load the plugin in a clean nvim
  (`--clean`/isolated, NOT the dev flake), `require("beans").setup()`, and assert the
  commands/detection exist. Wired into `ci.yml` as well as the release preflight — it is
  cheap and guards the setup() activation regression class directly.

## Risks / Trade-offs

- **Local `gh` auth required** to cut a release (decision B trade-off). Documented in
  RELEASING.md; the alternative (tag-triggered Actions) was declined for simplicity.
- **CHANGELOG discipline** is manual — the release notes are only as good as the
  `[Unreleased]` section; RELEASING.md makes keeping it current part of the flow.
- **panvimdoc not adopted** — `doc/beans.txt` stays hand-written; the helptags freshness
  check catches a stale/missing tags file but not prose drift from the README.
