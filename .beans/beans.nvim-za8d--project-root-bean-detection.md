---
# beans.nvim-za8d
title: Project root & bean detection
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:58:16Z
parent: beans.nvim-diz4
blocked_by:
    - beans.nvim-qmll
---

## Scope (project.lua, detect.lua)
- Walk up for `.beans.yml` (fallback `.beans/`); hand-rolled reader for `beans.path`.
- Two OR'd detection checks (path + content, first ~5 lines: `---`, `# <id>`, title).
- On match set `vim.b.beans = { id, root, beans_dir, bufnr }` and attach buffer-local
  keymaps via augroup `beans.nvim`. Do NOT set compound filetype.
- Non-bean markdown: zero keymaps/commands/autocmds/popups (hard requirement).
- checkhealth basics: binary+version, root, dir, recognised?/why-not, cache state.

## Acceptance
- [ ] Detects nested dirs, custom beans.path, archive/ files.
- [ ] Plain markdown outside a project: `vim.b.beans == nil`, no plugin keymap.
- [ ] Auto-start heuristic: fresh empty bean fires; old/bodied/disabled does not.

Briefing §6, §6.1, §11.1(3-4).

## Summary of Changes

- `project.lua`: upward search for `.beans.yml` (fallback `.beans/`), hand-rolled
  `beans.path` reader, `beans_dir`/`locate`. `detect.lua`: OR'd path + content checks,
  `content_id`, archive-aware `is_under`, ignore patterns; sets `vim.b.beans`.
- Auto-start heuristic (`should_autostart` + `parse_created_at`/`body_is_empty`), UTC-safe.
- `health.lua` basic `:checkhealth beans` (binary+version, root, dir, recognised?/why-not).
- `init.lua` wiring: FileType-markdown detection autocmd, attach (vim.b.beans, prefetch,
  keymaps, on_attach, autostart), BufWritePost list-cache invalidation.
- Tests: project_spec (6), detect_spec (13, incl. zero-footprint + autostart). All green.
