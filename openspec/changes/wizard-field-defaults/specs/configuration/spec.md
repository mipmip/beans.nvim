## ADDED Requirements

### Requirement: Enum step defaults are configurable per field

The default configuration table SHALL provide a `default` key under each of
`fields.status`, `fields.type` and `fields.priority`. Each SHALL be unset by default,
so that a configuration written before this feature existed behaves exactly as it did
before. A user SHALL be able to set any of them to a vocabulary value by passing a
partial table, without disturbing sibling keys such as `fields.priority.allow_clear`.

Only the enum fields SHALL carry this key. `fields.tags` and `fields.parent` SHALL NOT
gain a `default`, because their steps write on advance rather than on confirm.

#### Scenario: Defaults are absent until configured

- **WHEN** a user calls setup with no arguments
- **THEN** no `default` is set for `fields.status`, `fields.type` or `fields.priority`
- **AND** every enum step behaves as it did before this feature

#### Scenario: Setting one default preserves its siblings

- **WHEN** a user passes a configuration setting only `fields.priority.default`
- **THEN** the effective `fields.priority.default` is the value passed
- **AND** `fields.priority.allow_clear` retains its default
- **AND** `fields.tags` and `fields.parent` retain their defaults

### Requirement: A non-string field default warns once and is dropped

Validation at setup SHALL check that each configured `fields.<field>.default` is a
string. For a value of any other type the plugin SHALL emit at most one notification
naming the offending key, then drop that key so the field behaves as though no
default were configured. Setup SHALL NOT raise an error.

Validation at setup SHALL NOT check the value against a vocabulary. Vocabularies are
discovered per project at runtime and are not known when setup runs, so a value that
is a string SHALL be accepted here and checked by the wizard when the step opens.

#### Scenario: Wrong type falls back to no default

- **WHEN** a user configures `fields.priority.default` as a number
- **THEN** setup returns without error
- **AND** exactly one notification names the offending key
- **AND** the `priority` step starts its cursor on the first option when the field is unset

#### Scenario: An unknown string is accepted at setup

- **WHEN** a user configures `fields.priority.default` as a string that no vocabulary contains
- **THEN** setup returns without error and emits no notification about it
- **AND** the value is left in the effective configuration for the wizard to check
