## ADDED Requirements

### Requirement: Canonical module layout

The repository SHALL contain the module tree defined in the briefing (§9) as loadable
stubs: `lua/beans/{init,config,health,project,detect,cli,schema,frontmatter,completion,
actions}.lua`, `lua/beans/wizard/{init,ui}.lua`, and
`lua/beans/wizard/steps/{enum,tags,parent}.lua`, plus a `plugin/beans.lua` entry point.
Every module SHALL be `require`-able without error before its behaviour is implemented.

#### Scenario: All modules load as stubs

- **WHEN** `require("beans")` and each submodule are required in a fresh nvim
- **THEN** no error is raised, even though behaviour is not yet implemented

### Requirement: setup() is safe before implementation

`require("beans").setup()` SHALL NOT error, including when the `beans` binary is absent
from `PATH`. A missing binary SHALL degrade to a health-check concern rather than an
error out of `setup()`.

#### Scenario: setup with beans missing from PATH

- **WHEN** `require("beans").setup()` is called with no `beans` on `PATH`
- **THEN** it returns without error and the plugin still loads

### Requirement: Tooling configuration and formatting

The repository SHALL include a `stylua.toml`, and the committed skeleton SHALL pass
`stylua --check`. A `.gitignore` SHALL exclude the `.dev/` directory.

#### Scenario: Skeleton is formatted

- **WHEN** `stylua --check` is run on the repository
- **THEN** it reports no formatting differences

#### Scenario: Dev directory is ignored

- **WHEN** `.dev/` exists in the working tree
- **THEN** it is ignored by git via `.gitignore`

### Requirement: Documentation stubs

The repository SHALL include a `README.md` skeleton and a `doc/beans.txt` vimdoc stub,
to be filled in by later milestones.

#### Scenario: Docs present as stubs

- **WHEN** the repository is inspected
- **THEN** `README.md` and `doc/beans.txt` exist

### Requirement: Test harness skeleton

The repository SHALL include the `tests/` skeleton from the briefing (§9):
`tests/minimal_init.lua`, `tests/fixtures/`, `tests/helpers/`, and placeholder
`*_spec.lua` files, so later milestones add cases without restructuring. `plenary.nvim`
SHALL be a test-only dependency and MUST NOT be a runtime dependency of the plugin.

#### Scenario: Test layout exists

- **WHEN** the `tests/` directory is inspected
- **THEN** `minimal_init.lua`, `fixtures/`, `helpers/`, and spec placeholders exist and
  the plugin declares no runtime dependency on `plenary.nvim`
