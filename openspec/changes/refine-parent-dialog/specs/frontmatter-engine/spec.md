## MODIFIED Requirements

### Requirement: Scalar set

The engine SHALL set an existing scalar by replacing the value on its
`^(\s*)<key>:\s*(.*)$` line while preserving indentation. It SHALL quote the value only
when YAML requires it (the value contains `:`, `#`, leading/trailing whitespace, or is a
YAML-ambiguous word such as `yes`/`no`/`null`).

The engine SHALL accept an optional trailing comment. When a comment is supplied, it is
appended after the serialized (and, if needed, quoted) value as a YAML inline comment
(`<key>: <value> # <comment>`); the comment MUST NOT be folded into the value (so that
value quoting is unaffected). When replacing a value whose line already carries a trailing
` # …` comment, the engine SHALL drop the old comment (comments do not stack). When no
comment is supplied, the output is unchanged from the plain scalar set, so callers that
pass no comment remain byte-identical to `beans update`.

#### Scenario: Replace an existing scalar
- **WHEN** `status` is set to a new value on a bean that already has a `status:` line
- **THEN** only that line's value changes and its indentation is preserved

#### Scenario: Title containing a colon is quoted correctly
- **WHEN** a `title` value containing a colon is written
- **THEN** the value is quoted so the file remains valid YAML

#### Scenario: Byte-identical no-op
- **WHEN** a scalar is set to the value it already holds and no comment is supplied
- **THEN** the resulting lines are byte-identical to the input

#### Scenario: Scalar set with a trailing comment
- **WHEN** `parent` is set to an id with a comment of the parent's title
- **THEN** the line reads `parent: <id> # <title>` with the value serialized as usual

#### Scenario: Replacing a commented value does not stack comments
- **WHEN** `parent` already reads `parent: <old> # <old title>` and is set to a new id
  with a new comment
- **THEN** the line reads `parent: <new> # <new title>` with the old comment removed
