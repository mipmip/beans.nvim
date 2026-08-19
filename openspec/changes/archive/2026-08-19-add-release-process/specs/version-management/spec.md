## ADDED Requirements

### Requirement: Version source of truth
The repository SHALL carry a `VERSION` file as the single source of truth for the plugin
version, following semantic versioning, with `0.1.0` as the initial value. The plugin SHALL
expose this value as `require("beans").version`, and `:checkhealth beans` SHALL report it.

#### Scenario: Version is exposed to Lua
- **WHEN** a user evaluates `require("beans").version`
- **THEN** it returns the string in the `VERSION` file (e.g. `0.1.0`)

#### Scenario: checkhealth reports the plugin version
- **WHEN** the user runs `:checkhealth beans`
- **THEN** the report includes the plugin version from `VERSION`

### Requirement: Changelog and maintainer docs
The repository SHALL maintain a `CHANGELOG.md` in Keep a Changelog format with an
`[Unreleased]` section, and a `RELEASING.md` describing the release procedure. `RELEASING.md`
SHALL document the pre-1.0 semver convention (breaking changes ride a minor bump; a major
bump is the deliberate move to `1.0.0`).

#### Scenario: Unreleased section accumulates changes
- **WHEN** a change is merged before a release
- **THEN** it is recorded under the `[Unreleased]` section of `CHANGELOG.md`

#### Scenario: Releasing docs explain the pre-1.0 rule
- **WHEN** a maintainer reads `RELEASING.md`
- **THEN** it explains that below 1.0 breaking changes use a minor bump and major is the
  deliberate 1.0.0 step
