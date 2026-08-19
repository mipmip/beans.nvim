# wizard-tags-parent Specification

## Purpose
TBD - created by archiving change build-wizard. Update Purpose after archive.
## Requirements
### Requirement: Tags multi-select
The `tags` step SHALL present the project's tag universe as toggleable checkboxes, allow
movement between them, toggle selection, and confirm-and-advance. It MUST NOT auto-advance
on a toggle keypress.

#### Scenario: Toggle selects and deselects a tag
- **WHEN** the user moves to a tag and presses the toggle key twice
- **THEN** the tag is selected on the first press and deselected on the second, and the
  step does not advance

#### Scenario: Confirm writes the selected tags and advances
- **WHEN** the user has selected one or more tags and presses confirm
- **THEN** the selected tags are written to the frontmatter as a list and the wizard advances

### Requirement: In-buffer new-tag entry with validation
Adding a tag not yet in the project SHALL be done through an editable prompt line inside the
wizard buffer, never a blocking prompt. New tags SHALL be normalised (lowercased, trimmed)
and validated against `^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$`; an invalid tag SHALL be rejected
with a message rather than written.

#### Scenario: Valid new tag is added
- **WHEN** the user opens the new-tag prompt line, types a valid tag, and confirms
- **THEN** the tag is added to the selection and appears as a checked option

#### Scenario: Invalid new tag is rejected
- **WHEN** the user enters a new tag that fails the pattern
- **THEN** the tag is not written and a rejection message is shown

### Requirement: Parent filter-as-you-type
The `parent` step SHALL let the user filter candidate beans by typing (fuzzy match over
`"<id> <title>"`), move through the filtered list, select a candidate to set the parent and
advance, and clear an existing parent. The bean itself MUST always be excluded from
candidates, and candidates SHALL be restricted to the configured types by default.

#### Scenario: Typing narrows the candidate list
- **WHEN** the user types characters on the `parent` step
- **THEN** the candidate list narrows to fuzzy matches over `"<id> <title>"`

#### Scenario: The bean excludes itself from candidates
- **WHEN** the `parent` step lists candidates
- **THEN** the current bean's own id never appears in the list

#### Scenario: Selecting a candidate sets the parent and advances
- **WHEN** the user selects a filtered candidate
- **THEN** the `parent` value is written to the frontmatter and the wizard advances

#### Scenario: Clearing removes an existing parent
- **WHEN** the user presses the clear key on the `parent` step for a bean that has a parent
- **THEN** the `parent` line is removed from the frontmatter

