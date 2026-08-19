# plugin-qa-gates Specification

## Purpose
TBD - created by archiving change add-release-process. Update Purpose after archive.
## Requirements
### Requirement: Minimal-install smoke test
The project SHALL provide a smoke test that loads the plugin in a clean Neovim (isolated
from the developer's config and NOT using the dev flake's pre-wired setup), calls
`require("beans").setup()`, and asserts that the plugin is activated — the `:BeanWizard`
and `:Bean` commands exist and bean detection attaches on a bean buffer. This test SHALL
run both in CI (`ci.yml`) and in the `release.sh` preflight.

#### Scenario: A clean install activates the plugin
- **WHEN** a clean Neovim adds the plugin to its runtimepath and calls
  `require("beans").setup()`
- **THEN** `:BeanWizard` and `:Bean` exist and opening a bean sets `vim.b.beans`

#### Scenario: The smoke test gates CI and releases
- **WHEN** CI runs, or `release.sh` preflight runs
- **THEN** the minimal-install smoke test is executed and must pass

### Requirement: Lua linting with luacheck
The project SHALL include a `.luacheckrc` and run `luacheck` over `lua/` (and tests) as a
CI gate and in the release preflight, complementing `stylua` (which only checks formatting).

#### Scenario: luacheck runs in CI
- **WHEN** CI runs
- **THEN** `luacheck` is executed over the Lua sources and must pass

### Requirement: Help documentation stays in sync
The project SHALL verify that Vim help tags for `doc/beans.txt` are current (generatable via
`:helptags`) as a CI gate and in the release preflight, so `:help beans` resolves.

#### Scenario: Helptags freshness is checked
- **WHEN** CI runs, or `release.sh` preflight runs
- **THEN** the help tags for `doc/` are verified to be in sync

