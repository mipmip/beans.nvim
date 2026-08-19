## Context

The plugin is implemented and released (v0.2.1). Milestone `09 public release`
prepares it for a public audience. Two user-facing docs exist — `README.md`
(quickstart) and `doc/beans.txt` (vimdoc reference) — but both defer their
configuration reference to the internal `beans-nvim-briefing.md`, an 908-line
pre-implementation design spec. That briefing has drifted from the code (it predates
changes like `refine-parent-dialog`, so `fields.parent.title_comment` is missing from
its §7.3 table). Shipping docs that point users at a stale internal doc is the
blocker this change removes.

Constraint: this is a docs-and-comments change. No runtime Lua behaviour changes, so
the existing test suite (layers 1–4) should remain green without modification.

## Goals / Non-Goals

**Goals:**
- `doc/beans.txt` becomes the complete, self-contained user reference.
- `README.md` stays a lean quickstart, linking to `:help beans-*` rather than the
  briefing.
- Documented defaults are verified against `lua/beans/config.lua`, not copied from
  the briefing.
- The briefing is preserved for history at `docs/dev/beans-nvim-briefing.md` and no
  longer referenced by path from anywhere that still expects the old location.

**Non-Goals:**
- Rewriting or trimming the briefing's content (it moves verbatim).
- Copying internal-only briefing material (Beans ground truth §2, module layout §9,
  testing §11, verify-before-building §14) into user docs.
- Any change to plugin runtime behaviour or configuration schema.
- Generating vimdoc tooling/automation — `doc/beans.txt` stays hand-written.

## Decisions

**Source of truth for defaults is `lua/beans/config.lua`.**
The briefing is a design artifact and has demonstrably drifted. Every default that
appears in the docs is transcribed from the live `M.defaults` table. Rationale:
users copy defaults from docs; a wrong default is worse than an absent one.
Alternative considered — regenerate docs from config via a script — rejected as
over-engineering for a single hand-maintained help file (also a stated non-goal in
the briefing's own §9: "vimdoc, generated or hand-written").

**`doc/beans.txt` carries the full config table; README carries highlights only.**
The vimdoc is the canonical "full reference" per the bean. README keeps the short
illustrative snippet it already has (install → wizard → a few key options) and
swaps its briefing pointer for `:help beans-config`. This keeps the README scannable
while giving `:help` users the complete surface. Alternative — full table in both —
rejected as duplication that will drift.

**vimdoc section layout.** Extend the existing 7-section structure. Target ordering:
1 Introduction, 2 Setup, 3 The wizard, 4 Commands, 5 Keymaps, 6 Configuration
(expanded to the full table), 7 Highlight groups (new), 8 Completion (new),
9 Detection & troubleshooting (new; folds in the current Health section), 10
Non-goals (new), Health (kept, under troubleshooting). Each new section gets a
`*beans-<tag>*` help tag (`beans-highlights`, `beans-completion`,
`beans-detection`, `beans-non-goals`) and a matching CONTENTS entry, so README's
`:help beans-*` links resolve.

**Move the briefing with `jj`/git file move to preserve history**, to
`docs/dev/beans-nvim-briefing.md`. Then update path references. Two reference
classes:
- *Path references that must change*: `CLAUDE.md` (build playbook cites the file by
  path), README, `doc/beans.txt` (removed entirely per above).
- *Section-only references*: code comments like `-- …briefing.md §7.3` in
  `lua/beans/config.lua`, `frontmatter.lua`, `init.lua`, and `tests/frontmatter_spec.lua`.
  These get their path updated to the new location where a path is present; bare
  "§N" citations are left as-is.
- *Historical records left untouched*: `.beans/*.md` bean bodies are an archival log
  of past work and are not user or developer navigation aids; leave their briefing
  mentions as written.

## Risks / Trade-offs

- **Doc/code drift recurs later** → Mitigation: the spec requires defaults to match
  `config.lua`; the apply step transcribes from code, and a reviewer diff against
  `config.lua` is part of tasks.
- **Broken `:help` tags** (README links to a tag that doesn't exist) → Mitigation:
  add every new tag to the CONTENTS block and verify with `:helptags doc/` and a
  grep that each README `:help beans-*` target has a matching `*beans-*` tag.
- **Stale path reference missed** → Mitigation: a repo-wide grep for
  `beans-nvim-briefing` in tracked non-archive, non-`.beans` files as an acceptance
  check; only the moved file's own path and intentional historical mentions remain.
- **`doc/tags` staleness** → regenerate via `:helptags` after editing.

## Migration Plan

Docs-only; no runtime migration. Apply order: expand `doc/beans.txt` → update
`README.md` → `git mv` the briefing to `docs/dev/` → update path references →
regenerate `doc/tags` → grep/`:helptags` verification. Rollback is a revert of the
commit.
