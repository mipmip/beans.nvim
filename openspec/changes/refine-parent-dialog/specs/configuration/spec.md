## ADDED Requirements

### Requirement: Parent title comment default
The default `fields.parent.title_comment` SHALL be `true`, so that setting a parent through
the plugin writes the parent's title as a trailing YAML inline comment
(`parent: <id> # <title>`). Setting it to `false` SHALL write the bare id with no comment.

#### Scenario: Default enables the title comment
- **WHEN** `setup()` runs with no `fields.parent.title_comment` override
- **THEN** `fields.parent.title_comment` is `true`

#### Scenario: Override disables the title comment
- **WHEN** the user sets `fields.parent.title_comment = false`
- **THEN** the plugin writes `parent: <id>` with no trailing comment
