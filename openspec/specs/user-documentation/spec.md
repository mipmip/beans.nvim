# user-documentation Specification

## Purpose
TBD - created by archiving change docs-public-release. Update Purpose after archive.
## Requirements
### Requirement: User docs are self-contained

The end-user documentation (`README.md` and `doc/beans.txt`) SHALL NOT direct users
to the internal design briefing for any information needed to install, configure, or
use the plugin. No user-facing link or reference to `beans-nvim-briefing.md` SHALL
remain.

#### Scenario: README points to help tags, not the briefing

- **WHEN** a reader reaches the configuration section of `README.md`
- **THEN** it links to `:help beans-config` (and other `:help beans-*` tags) for the
  full reference
- **AND** it contains no reference to `beans-nvim-briefing.md`

#### Scenario: vimdoc points to itself, not the briefing

- **WHEN** a reader opens `doc/beans.txt`
- **THEN** every "full reference" pointer resolves within `doc/beans.txt` itself
- **AND** it contains no reference to `beans-nvim-briefing.md`

### Requirement: vimdoc is the complete reference

`doc/beans.txt` SHALL document the full configuration surface plus the sections a
user needs to customise and troubleshoot the plugin without reading source code:
the complete configuration reference, highlight groups, detection and auto-start
behaviour with troubleshooting, the `on_attach` / `on_finish` hooks, insert-mode
completion, and non-goals.

#### Scenario: complete config reference present

- **WHEN** a user searches `doc/beans.txt` for a configuration key
- **THEN** every top-level default key from `require("beans").setup{}` is documented
  with its default value and effect

#### Scenario: highlight groups documented

- **WHEN** a user wants to re-theme the wizard
- **THEN** `doc/beans.txt` lists each `Beans*` highlight group and the standard
  group it links to by default

#### Scenario: detection troubleshooting present

- **WHEN** the wizard does not fire on a bean the user expected it to
- **THEN** `doc/beans.txt` explains the detection checks (path and content) and the
  auto-start conditions (recognised bean, `created_at` within `max_age_seconds`,
  empty body) so the user can self-diagnose

#### Scenario: completion and hooks documented

- **WHEN** a user looks for insert-mode completion or lifecycle hooks
- **THEN** `doc/beans.txt` has a completion section (omnifunc, blink.cmp, nvim-cmp)
  and documents `hooks.on_attach` and `hooks.on_finish` with their arguments

### Requirement: Documented defaults match the shipped code

Every configuration default stated in the user docs SHALL match the value in
`lua/beans/config.lua`, which is the single source of truth. Documentation SHALL NOT
restate a default copied from the briefing when it differs from the code.

#### Scenario: parent title_comment default is correct

- **WHEN** the user docs describe `fields.parent`
- **THEN** they reflect `title_comment = true` as shipped in `lua/beans/config.lua`

#### Scenario: no default contradicts the code

- **WHEN** any default value appears in `README.md` or `doc/beans.txt`
- **THEN** it equals the corresponding value in `lua/beans/config.lua`

### Requirement: Briefing relocated and dereferenced

The internal design briefing SHALL live at `docs/dev/beans-nvim-briefing.md`, and
all path references to its old location SHALL be updated to the new path. References
that cite section numbers (e.g. "§7.3") without a path remain valid.

#### Scenario: briefing moved

- **WHEN** the change is applied
- **THEN** `beans-nvim-briefing.md` no longer exists at the repository root
- **AND** `docs/dev/beans-nvim-briefing.md` exists with the briefing's content

#### Scenario: path references updated

- **WHEN** a file (e.g. `CLAUDE.md`, or a code/test comment) refers to the briefing
  by path
- **THEN** that reference points at `docs/dev/beans-nvim-briefing.md`

