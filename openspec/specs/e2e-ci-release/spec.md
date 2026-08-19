# e2e-ci-release Specification

## Purpose
TBD - created by archiving change testing-e2e-release. Update Purpose after archive.
## Requirements
### Requirement: End-to-end wizard flow through a child Neovim

The suite SHALL include `e2e_spec` that spawns a real, separate Neovim
(`--embed --headless`) over RPC with the plugin on `runtimepath` and a temporary
Beans project on disk, drives it with `nvim_input` (real terminal-style keystrokes,
not `feedkeys`), and asserts on what the child reports.

#### Scenario: canonical create-and-fill loop closes through the CLI

- **WHEN** a bean file is written exactly as the TUI would (title + `created_at` = now
  + defaults + empty body), opened in the child nvim, the keys `i` `b` `h` are sent
  (status in-progress, type bug, priority high), then `<Tab>` `<Tab>` to skip tags and
  parent, then `<Esc>` and `:w<CR>`
- **THEN** the wizard float exists on open (a window whose config `relative ~= ""`),
  after finishing the mode is `i` with the cursor on the last body line and no float
  remains, and `beans show <id> --json` reports the three chosen values

#### Scenario: plain markdown outside a project is inert

- **WHEN** a plain markdown file outside any Beans project is opened in the child nvim
- **THEN** no float appears, `vim.b.beans` is `nil`, and pressing `<leader>bw` does
  nothing

### Requirement: CI gates every layer

CI SHALL run inside `nix develop` and MUST run `stylua --check` and test layers 1-4
headless against the nixvim-pinned Neovim plus stable and nightly Neovim.

#### Scenario: CI runs lint and all automated layers

- **WHEN** the CI workflow runs on a pull request
- **THEN** it executes `stylua --check` and layers 1-4 headless, and fails the build
  if lint fails or any layer fails

#### Scenario: CI covers multiple Neovim versions

- **WHEN** the CI workflow runs
- **THEN** the automated layers execute against the nixvim-pinned Neovim, stable, and
  nightly

### Requirement: Manual smoke checklist

The repository SHALL include `tests/MANUAL.md`, a short layer-5 checklist covering the
TUI → `$EDITOR` → nvim loop that is not automated, to be run in the flake's scratch
project before each release.

#### Scenario: checklist exists and covers the TUI loop

- **WHEN** a maintainer prepares a release
- **THEN** `tests/MANUAL.md` provides checkbox steps to create a bean from the TUI,
  complete all five wizard steps by keyboard only, `:wq`, confirm the TUI shows the
  chosen values, repeat with an immediate `<Esc>`, repeat inside a git worktree, and
  confirm a running `beans serve` web UI reflects the save

### Requirement: Documentation complete

The repository SHALL ship a complete `README.md` and `doc/beans.txt` vimdoc covering
installation, the wizard flow, keymaps, configuration, and the deliberate
inconsistency between letter-select and filter-select steps.

#### Scenario: docs cover the required topics

- **WHEN** a user reads `README.md` and `doc/beans.txt`
- **THEN** both cover install, the wizard flow, keymaps, config, and explicitly
  document that no-typing steps select by letter while typing steps select by filter

### Requirement: Definition of Done verified

Every item in the briefing §12 Definition of Done SHALL be verified before this change
is archived.

#### Scenario: all DoD boxes checked

- **WHEN** this change is prepared for archive
- **THEN** every §12 Definition-of-Done item is checked, including the layer-3 golden
  matrix passing byte-identically, the layer-4 e2e passing end to end with
  `beans show --json` confirmation, `nix develop` giving a working isolated nvim with
  `beans` available, and tests passing headless in CI

