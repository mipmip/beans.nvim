## Why

Three defects in the `parent` step and the random-access parent picker make parent
selection unusable in the common path:

1. In the full wizard flow the `parent` card shows the previous step's tag
   checkboxes instead of candidates — the filter query is seeded from stale float
   content (`beans.nvim-943x`).
2. The picker reached via `:Bean parent` / `<leader>bP` lists beans but does nothing
   when the user moves the cursor and presses `<CR>` — selection and navigation are
   bound only in insert mode and track an internal index, not the cursor line
   (`beans.nvim-0v6n`).
3. Features are offered as parent candidates; only milestones and epics should be
   (`beans.nvim-jql2`).

## What Changes

- The `parent` step starts with an **empty** filter query on entry and renders only
  the candidate list plus the clear entry — never content from a prior step.
- The `parent` step is fully operable in **normal mode**: `j`/`k` (and `<C-n>`/`<C-p>`)
  move, `<CR>` selects the candidate **under the cursor**; typing still filters. No
  behaviour depends on insert mode being successfully entered.
- The default `fields.parent.types` becomes `{ "milestone", "epic" }` (was
  `{ "milestone", "epic", "feature" }`); `nil` still means "offer every type".

## Capabilities

### New Capabilities

### Modified Capabilities
- `wizard-tags-parent`: the parent step must render without stale content and be
  operable in normal mode (select the candidate under the cursor).
- `configuration`: the default parent candidate types are milestones and epics only.

## Impact

- `lua/beans/wizard/steps/parent.lua` — render/keymap/selection changes.
- `lua/beans/config.lua` — default `fields.parent.types`.
- `tests/wizard_spec.lua` — normal-mode parent selection + no-stale-content specs.
- `tests/config_spec.lua` — default parent types.
- Docs: `README.md`, `beans-nvim-briefing.md` §7.3 note.
