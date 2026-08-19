---
# beans.nvim-0nqc
title: Version, changelog & maintainer docs
status: completed
type: epic
priority: normal
created_at: 2026-08-19T21:20:28Z
updated_at: 2026-08-19T21:36:25Z
parent: beans.nvim-cesp
---

VERSION file (0.1.0) as source of truth, surfaced as require("beans").version (shown
in :checkhealth). CHANGELOG.md (Keep a Changelog, [Unreleased] section). RELEASING.md
maintainer docs including the pre-1.0 semver note (breaking rides a minor bump; major is
the deliberate 1.0.0 button).

## Acceptance
- [ ] VERSION=0.1.0; require("beans").version returns it; checkhealth shows it.
- [ ] CHANGELOG.md + RELEASING.md present and accurate.

## Summary of Changes
VERSION=0.1.0 as source of truth, read into require("beans").version (via debug.getinfo
relative to init.lua) and reported by :checkhealth beans. CHANGELOG.md (Keep a Changelog,
[Unreleased]) and RELEASING.md (procedure + pre-1.0 semver note) added.
