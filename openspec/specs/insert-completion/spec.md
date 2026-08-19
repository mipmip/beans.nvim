# insert-completion Specification

## Purpose
TBD - created by archiving change config-commands-completion. Update Purpose after archive.
## Requirements
### Requirement: Omnifunc completes only inside frontmatter after known keys

In bean buffers the plugin SHALL set a buffer-local `omnifunc` that offers
completions only when the cursor is inside the frontmatter block and positioned
after a known key — on `status:`, `type:`, `priority:`, `parent:`, or a `tags:`
list item. Outside those conditions it SHALL return nothing so the user's normal
completion continues to work.

#### Scenario: completing a status value
- **WHEN** the cursor is on the `status:` line inside the frontmatter
- **THEN** the omnifunc offers the discovered status vocabulary

#### Scenario: silent outside frontmatter
- **WHEN** the cursor is in the body of the bean, outside the frontmatter block
- **THEN** the omnifunc returns no candidates

#### Scenario: silent after an unknown key
- **WHEN** the cursor is inside the frontmatter but on a line that is not a
  completable key (e.g. `created_at:`)
- **THEN** the omnifunc returns no candidates

### Requirement: Insert-mode completion adds no key mappings

The plugin SHALL NOT create any insert-mode `<Tab>` or `<CR>` mapping. The only
insert-mode action owned by the plugin SHALL be `startinsert` at wizard finish.

#### Scenario: no insert-mode Tab/CR mapping
- **WHEN** a bean buffer is active
- **THEN** the plugin has installed no insert-mode `<Tab>` or `<CR>` mapping

### Requirement: Optional cmp and blink sources stay optional

`blink.cmp` and `nvim-cmp` sources SHALL be registered only when their config flags
are enabled, SHALL default to disabled, and SHALL be lazily required so that neither
plugin is ever a hard dependency; when a flag is enabled but the plugin is absent,
the plugin SHALL NOT raise an error.

#### Scenario: sources disabled by default
- **WHEN** `setup()` runs with default completion config
- **THEN** neither `blink.cmp` nor `nvim-cmp` is required or registered

#### Scenario: enabled source with plugin absent
- **WHEN** `completion.cmp = true` but `nvim-cmp` is not installed
- **THEN** `setup()` completes without error and no source is registered

