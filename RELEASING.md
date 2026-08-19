# Releasing beans.nvim

A release of beans.nvim is just a **git tag** — plugin managers (lazy.nvim, packer,
mini.deps, …) check out a tag. There is nothing to compile or upload. Releases are cut
**manually** with `scripts/release.sh`.

## Prerequisites

- Run from a clean checkout on `main`, up to date with `origin`.
- `gh` authenticated locally (`gh auth status`) — the script creates the GitHub release.
- `gum` (provided by the flake devShell) and a plain `nvim` for the smoke test.

## Cutting a release

```sh
scripts/release.sh
```

The script:

1. Runs the **preflight gates** and aborts if any fails: clean/up-to-date `main`,
   `nix flake check`, `scripts/test.sh tests/` (all layers), `stylua --check`, `luacheck`,
   the minimal-install smoke test, and a `doc/` helptags freshness check.
2. Asks for the bump level with a `gum` chooser: **major / minor / patch**, computes the
   next version from `VERSION`, and asks you to confirm.
3. Updates `VERSION`, rolls the `[Unreleased]` section of `CHANGELOG.md` into a dated
   section for the new version, and adds a fresh `[Unreleased]`.
4. Commits with `jj`, moves `main`, and pushes.
5. Creates and pushes the `vX.Y.Z` git tag through the colocated git (`jj git push` does
   not push tags).
6. Creates the GitHub release with `gh release create`, using the new CHANGELOG section
   as the notes.

## Versioning (pre-1.0)

The bump chooser maps literally: `patch` → `0.1.0 → 0.1.1`, `minor` → `0.2.0`,
`major` → `1.0.0`. **Below `1.0.0`, breaking changes ride a `minor` bump**, and `major`
is the deliberate "we're stable now → `1.0.0`" step. Keep the `[Unreleased]` section of
`CHANGELOG.md` current as changes land — `release.sh` promotes it verbatim.
