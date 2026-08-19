# bean-detection Specification

## Purpose
TBD - created by archiving change build-data-layer. Update Purpose after archive.
## Requirements
### Requirement: Project root discovery

The system SHALL locate the Beans project root by walking upward from the buffer's
directory to find a `.beans.yml` file, falling back to a `.beans/` directory when no
config file is present. It SHALL read the `beans.path` key (default `.beans`) from
`.beans.yml` using a hand-rolled reader without introducing a YAML dependency.

#### Scenario: Root found from a nested directory
- **WHEN** a bean file is opened several directories below the project root
- **THEN** the system walks upward, finds `.beans.yml`, and resolves the project root
  and bean directory from its `beans.path`

#### Scenario: Custom beans.path is honoured
- **WHEN** `.beans.yml` sets `beans.path` to a non-default directory
- **THEN** the resolved bean directory reflects that custom path

#### Scenario: No project present
- **WHEN** no `.beans.yml` and no `.beans/` directory exist above the buffer
- **THEN** the system reports that no project root was found

### Requirement: Bean detection via two independent checks

The system SHALL recognise a buffer as a bean when EITHER a path check OR a content
check passes. The path check confirms the file lives under the resolved bean directory
(including its `archive/` subdirectory). The content check confirms the first
`detect.max_lines` lines contain a `---` fence, a `# <id>` comment, and a `title:` key.

#### Scenario: Detected by path
- **WHEN** a markdown file located inside the resolved bean directory is opened
- **THEN** the buffer is recognised as a bean

#### Scenario: Detected in the archive directory
- **WHEN** a markdown file located inside the bean directory's `archive/` is opened
- **THEN** the buffer is recognised as a bean

#### Scenario: Detected by content in a worktree or temp file
- **WHEN** a file whose path is uninformative but whose first lines carry `---`, a
  `# <id>` comment, and a `title:` key is opened
- **THEN** the buffer is recognised as a bean

### Requirement: State attachment on recognised beans

When a buffer is recognised as a bean, the system SHALL set the buffer variable
`vim.b.beans` to a table containing at least `id`, `root`, `beans_dir`, and `bufnr`, and
SHALL attach buffer-local keymaps. The system SHALL NOT set a compound filetype such as
`markdown.beans`.

#### Scenario: Buffer variable populated
- **WHEN** a bean buffer is detected
- **THEN** `vim.b.beans` is a table exposing the bean `id`, project `root`, `beans_dir`,
  and `bufnr`

#### Scenario: Filetype left unchanged
- **WHEN** a bean buffer is detected
- **THEN** the buffer `filetype` remains `markdown` (no compound filetype is set)

### Requirement: Zero footprint on non-bean markdown

The system SHALL NOT attach any keymaps, commands-with-effects, autocmds, or popups to
markdown buffers that are not recognised as beans.

#### Scenario: Plain markdown outside any Beans project
- **WHEN** a plain markdown file outside any Beans project is opened
- **THEN** `vim.b.beans` is `nil` AND no plugin buffer-local keymap exists in that buffer

### Requirement: Auto-start heuristic

The system SHALL expose an auto-start decision that is true only when ALL of the
following hold: the buffer is a recognised bean, its `created_at` is within
`autostart.max_age_seconds` of the current time, and (when `require_empty_body` is set)
its body is empty or whitespace-only. The heuristic MUST NOT rely on process detection.

#### Scenario: Fresh empty bean triggers auto-start
- **WHEN** a recognised bean has a `created_at` within the configured age and an empty body
- **THEN** the auto-start decision is true

#### Scenario: Old bean does not trigger
- **WHEN** a recognised bean's `created_at` is older than `autostart.max_age_seconds`
- **THEN** the auto-start decision is false

#### Scenario: Bean with a body does not trigger
- **WHEN** a recognised, recently created bean already has non-whitespace body content
  and `require_empty_body` is set
- **THEN** the auto-start decision is false

#### Scenario: Disabled auto-start never triggers
- **WHEN** `autostart.enabled` is false
- **THEN** the auto-start decision is false regardless of age or body

### Requirement: Health diagnostics for detection

The system SHALL provide `:checkhealth beans` output reporting at least whether the
`beans` binary was found and its version, the detected project root and bean directory,
and — for the current buffer — whether it is recognised as a bean and, if not, why.

#### Scenario: Detection failure is self-explaining
- **WHEN** the current buffer is not recognised as a bean and the user runs
  `:checkhealth beans`
- **THEN** the report states that the buffer is not recognised and gives the reason

