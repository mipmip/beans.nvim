---
# beans.nvim-8dyu
title: move relevant documentation from briefing to readme.md and docs/beans.txt
status: completed
type: task
priority: normal
tags:
    - documentation
created_at: 2026-08-19T21:16:12Z
updated_at: 2026-08-19T23:14:16Z
parent: beans.nvim-tnpw
---

check in the briefing for stuff thats is relevant and actual and not available in the readme.md (quickstart stuff) and in the docs/beans.txt (full reference)

## Summary of Changes

Made `README.md` and `doc/beans.txt` self-sufficient for the public release; no
user-facing doc points at the internal briefing any more.

- `doc/beans.txt` (`:help beans`) is now the complete reference: full config table
  (transcribed from `lua/beans/config.lua`, the source of truth), highlight groups,
  insert-mode completion, `on_attach`/`on_finish` hooks, and a
  detection/troubleshooting section ("why didn't the wizard fire?"). New help tags:
  `beans-highlights`, `beans-completion`, `beans-detection`, `beans-non-goals`,
  `beans-hooks`, `beans-requirements`, `beans-wizard-keys`.
- `README.md` links to `:help beans-config` instead of the briefing.
- Relocated `beans-nvim-briefing.md` to `docs/dev/beans-nvim-briefing.md` and
  updated all path references (`CLAUDE.md`, comments in `config.lua`,
  `init.lua`, `frontmatter.lua`, `tests/frontmatter_spec.lua`).
- Corrected two doc/code drifts surfaced while verifying against the source:
  `fields.parent.title_comment = true` (absent from the briefing table) and
  `BeansWizardCurrent → PmenuSel` (briefing said `CursorLine`).

Note: the bean said `docs/beans.txt`; the real target is `doc/beans.txt`, Neovim's
vimdoc convention. Shipped as OpenSpec change `docs-public-release` (capability
`user-documentation`). Gate green: stylua, luacheck, tests (layers 1–4), helptags
freshness.
