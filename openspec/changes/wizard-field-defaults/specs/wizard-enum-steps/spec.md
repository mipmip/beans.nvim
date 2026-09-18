## ADDED Requirements

### Requirement: Configured default positions the cursor on an unset field

When an enum step opens for a field that has no value in the frontmatter, the step
SHALL place its cursor on the value configured as `fields.<field>.default`, provided
that value is present in the step's option list. When no default is configured, or
the configured value is absent from the option list, the cursor SHALL start on the
first option, which is the behaviour without this feature.

A configured default SHALL NOT be written to the buffer by the act of opening the
step. The buffer SHALL change only when the user confirms a value with the select
key or a mnemonic. Advancing with the next key SHALL leave the field unset.

#### Scenario: Cursor starts on the configured default

- **WHEN** the `priority` step opens on a bean whose frontmatter has no `priority:` key
- **AND** `fields.priority.default` is configured as `normal`
- **THEN** the cursor is positioned on the `normal` option
- **AND** the buffer is byte-identical to what it was before the step opened

#### Scenario: Advancing past the step writes nothing

- **WHEN** the cursor sits on a configured default for an unset field
- **AND** the user presses the next key
- **THEN** the wizard advances to the following step
- **AND** no key for that field is added to the frontmatter

#### Scenario: Confirming the default writes it

- **WHEN** the cursor sits on a configured default for an unset field
- **AND** the user presses the select key
- **THEN** that value is written to the frontmatter and the wizard advances

#### Scenario: No default configured leaves today's behaviour

- **WHEN** an enum step opens for an unset field and no default is configured for it
- **THEN** the cursor is positioned on the first option

### Requirement: A value already set takes precedence over the default

The configured default SHALL apply only when the field is absent from the
frontmatter or carries an empty value. A field that carries any non-empty value
SHALL be treated as set, and the cursor SHALL follow the existing rule of starting
on the currently-set value. A set value that is not present in the discovered
vocabulary SHALL still count as set: the step SHALL leave the cursor on the first
option rather than moving it to the configured default, so that the frontmatter is
reported as it stands rather than masked.

#### Scenario: Set value wins over the configured default

- **WHEN** the `priority` step opens on a bean whose frontmatter reads `priority: high`
- **AND** `fields.priority.default` is configured as `normal`
- **THEN** the cursor is positioned on the `high` option

#### Scenario: Set but unrecognised value suppresses the default

- **WHEN** the `priority` step opens on a bean whose frontmatter reads `priority: urgent`
- **AND** `urgent` is absent from the discovered vocabulary
- **AND** `fields.priority.default` is configured as `normal`
- **THEN** no option is marked active
- **AND** the cursor is positioned on the first option rather than on `normal`

### Requirement: A default outside the vocabulary warns once per project and field

When a configured default is absent from the vocabulary discovered for the current
project, the wizard SHALL emit at most one warning naming the field, the configured
value and the accepted values, then fall back to placing the cursor on the first
option. The wizard SHALL NOT raise an error and SHALL NOT block the step.

The check SHALL be made only against a vocabulary that was discovered from the beans
CLI for that field. While the field's vocabulary is unresolved and the configured
`fallback` table is standing in for it, the wizard SHALL NOT warn, so that a project
with a customised vocabulary does not see a warning that a later re-render retracts.

The warning SHALL be emitted at most once per project root per field for the
lifetime of the session, so that re-entering a step, navigating back to it, or
re-rendering it when prefetched data arrives does not repeat it. The warning SHALL
respect the configured notification level in the same way as validation warnings
raised at setup.

#### Scenario: Unknown default warns and falls back

- **WHEN** `fields.priority.default` is configured as `urgent`
- **AND** the vocabulary discovered for the project does not contain `urgent`
- **THEN** one warning names the field, the configured value and the accepted values
- **AND** the cursor is positioned on the first option

#### Scenario: Re-entering the step does not repeat the warning

- **WHEN** a step has already warned about its configured default in this project
- **AND** the user navigates back to that step, or the step re-renders on prefetched data
- **THEN** no further warning is emitted

#### Scenario: An unresolved vocabulary stays silent

- **WHEN** an enum step renders before the field's vocabulary has been discovered
- **AND** the option list is being supplied by the configured `fallback` table
- **THEN** no warning is emitted regardless of the configured default

#### Scenario: Warnings honour the notify setting

- **WHEN** notifications are disabled in the configuration
- **AND** a configured default is absent from the discovered vocabulary
- **THEN** no notification is emitted and the cursor falls back to the first option
