## Why

For the public release (milestone `09 public release`, bean `beans.nvim-8dyu`), the
two user-facing docs outsource their reference content to an internal build spec:
`README.md` and `doc/beans.txt` both tell users the complete config table "lives in
`beans-nvim-briefing.md` §7.3". That is backwards for a released plugin — end users
and `:help` should never be pointed at a 908-line pre-implementation design
document, which has *also already drifted* from the shipped code (e.g.
`fields.parent.title_comment = true` exists in `lua/beans/config.lua` but not in the
briefing's §7.3 table). The docs must stand on their own before release.

## What Changes

- Make `doc/beans.txt` the **self-sufficient full reference**, sourcing every
  documented default from `lua/beans/config.lua` (the source of truth), not the
  briefing. Add the currently-missing sections:
  - the complete configuration reference (§7.3 equivalent, verified against code),
  - highlight groups and what they link to (§7.4),
  - detection and "why the wizard didn't fire" troubleshooting (§6 / §6.1),
  - the `hooks.on_attach` / `hooks.on_finish` escape hatches,
  - an insert-mode completion section (omnifunc / blink.cmp / nvim-cmp, §8),
  - non-goals so users know what beans.nvim deliberately does not do (§13).
- Keep `README.md` as the quickstart: retain the short config highlights but
  replace the pointer to `beans-nvim-briefing.md` with `:help beans-config` (and
  other `:help beans-*` tags). No user-facing link to the briefing remains.
- Relocate `beans-nvim-briefing.md` to `docs/dev/beans-nvim-briefing.md` for
  historical completeness, and update path references that point at it
  (`CLAUDE.md`, code/test comments) to the new location. Section-number references
  (e.g. "§7.3") stay valid.
- Internal-only briefing content is **not** copied into user docs and stays in the
  briefing: ground truth about Beans (§2), module layout (§9), testing (§11),
  verify-before-building (§14).

## Capabilities

### New Capabilities
- `user-documentation`: The end-user documentation surface (README quickstart +
  `doc/beans.txt` vimdoc reference) must be self-contained and accurate against the
  shipped configuration, with no user-facing dependency on the internal design
  briefing.

### Modified Capabilities
<!-- None: no existing plugin-behavior spec changes its requirements. -->

## Impact

- `doc/beans.txt` — substantially expanded into the full reference.
- `README.md` — briefing pointer replaced with `:help beans-*` links.
- `beans-nvim-briefing.md` → `docs/dev/beans-nvim-briefing.md` (moved).
- Path references updated: `CLAUDE.md`, and code/test comments in
  `lua/beans/config.lua`, `lua/beans/frontmatter.lua`, `lua/beans/init.lua`,
  `tests/frontmatter_spec.lua`.
- No runtime code behavior changes; docs and comments only.
