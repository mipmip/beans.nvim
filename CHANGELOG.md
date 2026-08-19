# Changelog

All notable changes to beans.nvim are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/). While the version is below `1.0.0`,
breaking changes may occur on a minor bump.

## [Unreleased]

## [0.2.1] - 2026-08-19

## [0.2.0] - 2026-08-19

### Added

- Isolated Nix flake dev environment (plain-nix multi-system, no flake-utils) with
  NixVim and the `beans` CLI available.
- Bean detection (by path or content), the auto-start heuristic, and `:checkhealth beans`.
- Async `beans` CLI wrapper, runtime vocabulary discovery, dynamic mnemonics, and
  per-project prefetch/caching.
- Pure frontmatter engine that edits bean YAML in canonical order, byte-identical to
  `beans update`.
- The wizard: near-cursor float with `status`/`type`/`priority`/`tags`/`parent` steps,
  single-keystroke enum selection, one undo step per field, and no blocking prompts.
- Zero-argument `setup()` with validate-and-warn, `:BeanWizard` / `:Bean` / `:Bean <field>`
  commands, buffer-local keymaps, and opt-in insert-mode completion (omnifunc + optional
  blink/cmp sources).
- A clear selection indicator (caret) on wizard cards; the parent value carries the
  parent's title as a trailing comment (`fields.parent.title_comment`, default on).
- Five-layer test suite (unit, in-process wizard, golden-file equivalence, child-nvim
  e2e, manual checklist) and CI.
- Release process: `VERSION` file surfaced as `require("beans").version` (and in
  `:checkhealth`), this changelog, `RELEASING.md`, a manual `scripts/release.sh`, and
  plugin QA gates (minimal-install smoke test, luacheck, helptags freshness).

### Fixed

- The dev flake now calls `require("beans").setup()` so the plugin activates in the
  dev editor.
- Parent step: no longer shows the previous step's content, is operable in normal mode
  (`j`/`k` + `<CR>` selects the candidate under the cursor), and offers milestones and
  epics only by default.

[Unreleased]: https://github.com/mipmip/beans.nvim/commits/main
