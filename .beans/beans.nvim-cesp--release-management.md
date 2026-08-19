---
# beans.nvim-cesp
title: 08 Release management
status: todo
type: milestone
priority: normal
tags:
    - management
created_at: 2026-08-19T15:13:09Z
updated_at: 2026-08-19T21:20:28Z
---

Goal: a repeatable, manual release process and the QA gates a Neovim plugin needs
before its first tag. Adapts the huphop `add-release-process` pattern, dropping all
Go/binary machinery (goreleaser, go:embed, vendorHash) — a plugin release is a git tag.

Tracked as OpenSpec change: `add-release-process`.

## Epics
- Version, changelog & docs
- Release automation (manual, scripts/release.sh)
- Plugin QA gates

## Decisions (explore session)
- First version 0.1.0; releases cut manually via scripts/release.sh with a gum
  major/minor/patch dropdown; the script cuts the GitHub release directly
  (gh release create), no release.yml. Tags go via the colocated git.
