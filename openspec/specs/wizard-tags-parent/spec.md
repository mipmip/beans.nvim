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
`"<id> <title>"`), move through the list, select a candidate to set the parent and
advance, and clear an existing parent. The bean itself MUST always be excluded from
candidates, and candidates SHALL be restricted to the configured types by default.

On entry the step SHALL start with an empty filter query and render only the candidate
list (plus the clear entry); it MUST NOT display any content carried over from a prior
step. The step SHALL be fully operable in normal mode: the user SHALL be able to move
the cursor with `j`/`k` (and `<C-n>`/`<C-p>`) and press `<CR>` to select the candidate
under the cursor, without relying on insert mode having been entered. Typing still
narrows the list. All input MUST be handled by buffer-local keymaps on the wizard
buffer (no blocking prompt).

When `fields.parent.title_comment` is enabled, selecting a candidate SHALL write the
`parent` value with the candidate's title as a trailing YAML inline comment
(`parent: <id> # <title>`); when disabled, the bare id SHALL be written.

#### Scenario: Entering the step shows no stale content
- **WHEN** the wizard advances into the `parent` step from a previous step
- **THEN** the card shows only the candidate list and the clear entry, and the filter
  query is empty

#### Scenario: Typing narrows the candidate list
- **WHEN** the user types characters on the `parent` step
- **THEN** the candidate list narrows to fuzzy matches over `"<id> <title>"`

#### Scenario: The bean excludes itself from candidates
- **WHEN** the `parent` step lists candidates
- **THEN** the current bean's own id never appears in the list

#### Scenario: Selecting the candidate under the cursor in normal mode
- **WHEN** the user moves the cursor with `j`/`k` onto a candidate and presses `<CR>` in
  normal mode
- **THEN** that candidate's id is written as the `parent` and the wizard advances

#### Scenario: Selecting writes the parent title as a trailing comment
- **WHEN** `fields.parent.title_comment` is enabled and the user selects a candidate
- **THEN** the `parent` line reads `parent: <id> # <title>`

#### Scenario: Title comment can be disabled
- **WHEN** `fields.parent.title_comment` is false and the user selects a candidate
- **THEN** the `parent` line reads `parent: <id>` with no trailing comment

#### Scenario: Clearing removes an existing parent
- **WHEN** the user selects the clear entry on the `parent` step for a bean that has a
  parent
- **THEN** the `parent` line is removed from the frontmatter

