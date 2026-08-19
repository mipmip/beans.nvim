# wizard-enum-steps Specification

## Purpose
TBD - created by archiving change build-wizard. Update Purpose after archive.
## Requirements
### Requirement: Single-keypress enum selection
For the `status`, `type`, and `priority` steps, pressing an option's mnemonic key SHALL
both select the value and advance to the next step in a single keystroke.

#### Scenario: Mnemonic keypress applies the value and advances
- **WHEN** the user presses an option's mnemonic on the `status` step
- **THEN** that status is written to the frontmatter and the wizard advances to the next step

#### Scenario: Selecting the current value is a no-op edit
- **WHEN** the user presses the mnemonic for the value already set on the field
- **THEN** the wizard advances and the buffer is left byte-identical

### Requirement: Dynamic mnemonic assignment
Mnemonics SHALL be computed from the discovered vocabulary at runtime — first letter, then
the next unused letter in the word, then digits `1..9` — and MUST NOT be hardcoded.
Configured overrides SHALL take precedence.

#### Scenario: Colliding first letters fall through to a free letter or digit
- **WHEN** two options in a field share a first letter
- **THEN** the second option is assigned its next unused letter, or a digit if none is free,
  with no duplicate mnemonics

#### Scenario: Configured override wins
- **WHEN** a mnemonic override is configured for a value
- **THEN** that value uses the configured key and other values are assigned around it

### Requirement: Enum options show current value and hints
Each enum step SHALL indicate which value is currently set on the bean and MAY show a short
description beside each option.

#### Scenario: Current value is marked
- **WHEN** an enum step opens for a field that already has a value
- **THEN** that value's option is visibly marked as the active one

### Requirement: Priority clear entry
The `priority` step SHALL offer a "clear" entry when `fields.priority.allow_clear` is set;
`status` and `type` SHALL NOT offer a clear entry. Clearing priority SHALL remove the line
from the frontmatter rather than writing an empty value.

#### Scenario: Clearing priority removes the line
- **WHEN** the user chooses the clear entry on the `priority` step
- **THEN** the `priority:` line is removed from the frontmatter and the wizard advances

