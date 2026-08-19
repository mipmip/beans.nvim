# golden-equivalence Specification

## Purpose
TBD - created by archiving change testing-e2e-release. Update Purpose after archive.
## Requirements
### Requirement: Byte-identical equivalence with the Beans CLI

The plugin's `frontmatter.lua` output SHALL be byte-identical to the output of
`beans update` for the same field change, apart from the `updated_at` field. This
equivalence MUST hold across the full scenario matrix and MUST be asserted by
`golden_spec`.

#### Scenario: field-change matrix is byte-identical

- **WHEN** for each scenario in the matrix — set status; set type; set priority; clear
  priority; add one tag; add three tags; remove a tag; remove all tags; set parent;
  clear parent; and set a title containing a colon — applied against both a
  fully-populated bean and a minimal bean, a bean is created in a temp `beans init`
  project, copied to `A.md` and `B.md`, the change applied to A via `beans update` and
  to B via the plugin's `frontmatter.lua`
- **THEN** `A.md` and `B.md` are byte-identical apart from the `updated_at` value

#### Scenario: canonical insertion order preserved

- **WHEN** a change inserts an optional key that was absent (e.g. `type`, `priority`,
  `parent`, or `tags`) into a minimal bean
- **THEN** the key lands in the canonical field order and the resulting file matches
  what `beans update` produced for the same change

### Requirement: Goldens committed and drift-detected

Committed golden files SHALL let the matrix run without a `beans` binary, and a
scheduled CI job MUST regenerate the goldens against the latest Beans release and fail
if they differ, so upstream schema drift is caught early.

#### Scenario: matrix runs without a beans binary

- **WHEN** `golden_spec` runs in an environment with no `beans` binary on `PATH`
- **THEN** it compares the plugin output against the committed `fixtures/golden/` files
  and reports pass/fail without invoking the CLI

#### Scenario: scheduled regeneration detects upstream drift

- **WHEN** the scheduled golden-regeneration job runs against the latest Beans release
- **THEN** it regenerates the golden files and fails loudly if any differ from the
  committed versions, signalling a Beans frontmatter format change

