# commands-keymaps Specification

## Purpose
TBD - created by archiving change config-commands-completion. Update Purpose after archive.
## Requirements
### Requirement: User commands are available in bean buffers

The plugin SHALL provide `:BeanWizard` (start the wizard at step 1), `:Bean` (field
menu, then value picker), `:Bean <field>` (jump straight to one field, with
completion on field names), and `:checkhealth beans` diagnostics.

#### Scenario: launching the wizard by command
- **WHEN** a user runs `:BeanWizard` in a recognised bean buffer
- **THEN** the wizard float opens at step 1

#### Scenario: field-name completion on :Bean
- **WHEN** a user types `:Bean ` and requests command-line completion
- **THEN** the candidates are the recognised field names (status, type, priority,
  tags, parent)

### Requirement: Buffer-local keymaps attach only in bean buffers

The default buffer-local keymaps SHALL attach only to recognised bean buffers, SHALL
be fully disable-able via `keymaps.enabled = false` and individually overridable, and
a plain markdown file outside any Beans project SHALL receive no plugin keymap. The
keymaps covered are those of briefing §7.2: wizard, menu, status, type, priority,
tags, and parent.

#### Scenario: keymaps present in a bean buffer
- **WHEN** a recognised bean buffer is opened with default config
- **THEN** the `<leader>bw` wizard keymap and the field keymaps are buffer-local to it

#### Scenario: no keymaps in non-bean markdown
- **WHEN** a plain markdown file outside any Beans project is opened
- **THEN** no beans.nvim keymap exists in that buffer

#### Scenario: keymaps disabled globally
- **WHEN** a user sets `keymaps.enabled = false` and opens a bean buffer
- **THEN** no beans.nvim keymap is attached

### Requirement: Random-access field editing prefers the open buffer

`:Bean` and `:Bean <field>` SHALL edit the frontmatter through the buffer-edit code
path when the target bean is open in a buffer, and SHALL fall back to `beans update`
only when acting on a bean that is not currently open in any buffer.

#### Scenario: editing a field of an open bean
- **WHEN** a user changes a field via `:Bean <field>` while the bean is open
- **THEN** the change is applied as a buffer edit (one undo step, no disk write until `:w`)

### Requirement: Lifecycle hooks fire with the bean context

The plugin SHALL invoke `hooks.on_attach(ctx)` after detection and
`hooks.on_finish(ctx, changed)` after the wizard closes, where `ctx` carries
`{ id, root, beans_dir, bufnr }` and `changed` is the list of changed field names.

#### Scenario: on_attach receives context
- **WHEN** a bean buffer is detected and `hooks.on_attach` is configured
- **THEN** it is called once with the bean context table

#### Scenario: on_finish receives changed fields
- **WHEN** the wizard closes after changing fields and `hooks.on_finish` is configured
- **THEN** it is called with the context table and the list of changed field names

### Requirement: checkhealth explains detection outcomes

`:checkhealth beans` SHALL report the `beans` binary and version, the detected
project root and bean directory, whether the current buffer is recognised and why
not if it is not, the discovered vocabularies, and cache state.

#### Scenario: diagnosing a detection failure
- **WHEN** a buffer is not recognised as a bean and the user runs `:checkhealth beans`
- **THEN** the report states that the buffer is not recognised and the reason why

