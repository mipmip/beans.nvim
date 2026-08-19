## ADDED Requirements

### Requirement: Frontmatter location and guard

The frontmatter engine SHALL operate on a list of lines and SHALL locate the frontmatter
block from a line 1 that is exactly `---` to the next `---`. When line 1 is not exactly
`---`, the engine SHALL treat the input as not a bean and make no edits.

#### Scenario: Non-bean input is left untouched
- **WHEN** the first line of the input is not exactly `---`
- **THEN** the engine performs no edits and reports that the buffer is not a bean

### Requirement: Preserve comments and Beans-owned fields

The engine SHALL preserve the `# <id>` comment line and any other comment lines verbatim,
and SHALL never modify `created_at`, `updated_at`, or `order`.

#### Scenario: ID comment and timestamps preserved across an edit
- **WHEN** any field is set on a bean carrying a `# <id>` comment, `created_at`,
  `updated_at`, and `order`
- **THEN** the `# <id>` comment line and the `created_at`, `updated_at`, and `order`
  lines remain byte-identical

### Requirement: Scalar set

The engine SHALL set an existing scalar by replacing the value on its
`^(\s*)<key>:\s*(.*)$` line while preserving indentation. It SHALL quote the value only
when YAML requires it (the value contains `:`, `#`, leading/trailing whitespace, or is a
YAML-ambiguous word such as `yes`/`no`/`null`).

#### Scenario: Replace an existing scalar
- **WHEN** `status` is set to a new value on a bean that already has a `status:` line
- **THEN** only that line's value changes and its indentation is preserved

#### Scenario: Title containing a colon is quoted correctly
- **WHEN** a `title` value containing a colon is written
- **THEN** the value is quoted so the file remains valid YAML

#### Scenario: Byte-identical no-op
- **WHEN** a scalar is set to the value it already holds
- **THEN** the resulting lines are byte-identical to the input

### Requirement: Scalar insert in canonical order

When a scalar key is absent, the engine SHALL insert it at the position dictated by the
canonical field order
`title, status, type, priority, tags, created_at, updated_at, order, parent, blocking, blocked_by`,
relative to the keys already present.

#### Scenario: Insert type when missing
- **WHEN** `type` is set on a bean that has `title` and `status` but no `type`
- **THEN** the new `type:` line is inserted immediately after `status:` and before any
  later canonical key

#### Scenario: Insert parent into a minimal bean
- **WHEN** `parent` is set on a bean that contains only `title` and `status`
- **THEN** the `parent:` line is inserted at its canonical position after the earlier keys

### Requirement: Scalar clear

The engine SHALL clear a scalar (e.g. `priority`) by removing its line entirely rather
than writing an empty value.

#### Scenario: Clearing priority removes the line
- **WHEN** `priority` is cleared on a bean that has a `priority:` line
- **THEN** the `priority:` line is removed and no empty `priority:` remains

### Requirement: List set and clear

The engine SHALL write a list value (e.g. `tags`) as a YAML block sequence. When a
`tags:` block already exists it SHALL match that block's existing indentation; otherwise
it SHALL use Beans' emitted indentation. Clearing a list SHALL remove the key and all its
items.

#### Scenario: Write a tag list
- **WHEN** `tags` is set to a list of values on a bean without existing tags
- **THEN** a `tags:` block sequence is written at the canonical position with Beans'
  indentation

#### Scenario: Existing tag block indentation is matched
- **WHEN** `tags` is updated on a bean that already has a `tags:` block
- **THEN** the rewritten items use the existing block's indentation

#### Scenario: Clearing tags removes the key and items
- **WHEN** all tags are removed
- **THEN** the `tags:` key and every list item under it are removed

### Requirement: One edit per field for single-step undo

Each field change SHALL be applied to the buffer as a single `nvim_buf_set_lines` call so
that the change is exactly one undo step.

#### Scenario: A field change is one undo step
- **WHEN** a single field is applied to a live buffer and then undone once
- **THEN** the buffer returns to its state prior to that field change
