## MODIFIED Requirements

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
