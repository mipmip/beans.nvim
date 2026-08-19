## ADDED Requirements

### Requirement: Parent candidate types default to milestones and epics
The default `fields.parent.types` SHALL be `{ "milestone", "epic" }`, so that only
milestones and epics are offered as parent candidates unless the user overrides the
setting. A user-supplied list SHALL replace the default, and `nil` SHALL mean "offer
candidates of every type".

#### Scenario: Default excludes non-milestone/epic types
- **WHEN** `setup()` runs with no `fields.parent.types` override
- **THEN** `fields.parent.types` equals `{ "milestone", "epic" }` and feature/bug/task
  beans are not offered as parent candidates

#### Scenario: Override is honoured
- **WHEN** the user sets `fields.parent.types` to a custom list (or `nil`)
- **THEN** candidates are restricted to that list (or unrestricted when `nil`)
