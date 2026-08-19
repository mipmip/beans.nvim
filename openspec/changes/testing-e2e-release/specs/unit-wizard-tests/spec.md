## ADDED Requirements

### Requirement: Hermetic test harness

The test suite SHALL run headlessly without a real `beans` binary and without
network access. It MUST provide `tests/minimal_init.lua`, an executable
`tests/fixtures/fake-beans` stub placed on `PATH` that emits canned `beans update
--help` text and canned `beans list`/`beans show` JSON, and shared helpers
`tests/helpers/project.lua` (builds a temporary Beans project on disk) and
`tests/helpers/child.lua` (spawns and drives a child Neovim over RPC).

#### Scenario: Suite runs with no real beans binary

- **WHEN** `PlenaryBustedDirectory tests/` is invoked headless with only
  `tests/fixtures/fake-beans` on `PATH`
- **THEN** layer-1 and layer-2 specs execute and report pass/fail without invoking
  the real `beans` CLI and without network access

#### Scenario: fake-beans emits canned vocabulary and JSON

- **WHEN** a spec runs `beans update --help`, `beans list --json`, or
  `beans show <id> --json` through the stub
- **THEN** the stub returns deterministic canned output matching the real CLI's shape
  so schema discovery, prefetch, and detection code paths are exercised

### Requirement: Layer-1 unit specs

The suite SHALL include hermetic layer-1 specs `frontmatter_spec`, `schema_spec`,
`project_spec`, `detect_spec`, and `config_spec`, prioritised by blast radius per
briefing §11.1, all passing headless via `PlenaryBustedDirectory`.

#### Scenario: frontmatter engine coverage

- **WHEN** `frontmatter_spec` runs
- **THEN** it asserts scalar replace; scalar insert at the correct canonical position
  for every gap (type-missing, priority-missing, parent-missing, tags-missing, and a
  bean with only `title`+`status`); scalar clear; tag-list write and clear;
  preservation of the `# <id>` comment, `created_at`, `updated_at`, and `order`;
  titles containing colons, quotes, `#`, and leading/trailing space; and that setting
  a value to what it already was leaves the lines byte-identical

#### Scenario: schema and detection coverage

- **WHEN** `schema_spec`, `project_spec`, and `detect_spec` run
- **THEN** they assert help-text vocabulary parsing including the `or empty to clear`
  tail, fallback when parsing fails or the binary is missing, mnemonic assignment
  including a forced-collision vocabulary that falls through to digits, root detection
  from nested dirs and custom `beans.path` and `archive/` files, and the negative case
  that a plain markdown file outside a Beans project attaches nothing

#### Scenario: auto-start heuristic coverage

- **WHEN** the auto-start specs run
- **THEN** they assert the wizard auto-starts on a fresh empty bean and does NOT
  auto-start on an old bean, a bean with a non-empty body, or when disabled

### Requirement: Layer-2 in-process wizard specs

The suite SHALL include `wizard_spec` that drives the real wizard against a real
buffer in-process, relying on the no-blocking-prompt guarantee so
`nvim_feedkeys(keys, "x", false)` executes synchronously.

#### Scenario: wizard interaction coverage

- **WHEN** `wizard_spec` runs
- **THEN** it asserts step sequencing; that a mnemonic keypress applies the value and
  auto-advances; that `<S-Tab>` returns with the previous pick highlighted; that
  `<Tab>` on an unchanged field advances without dirtying the buffer; that `<Esc>`
  exits from every step; one-undo-step-per-field (apply five fields, press `u` five
  times, buffer matches the original exactly); that finishing leaves the cursor on the
  last body line in insert mode; and tags toggle/new-tag plus parent filter narrowing
  and self-exclusion

### Requirement: No blocking prompts in the wizard path

The wizard path SHALL contain no blocking prompt. A grep-as-test MUST fail if
`vim.fn.input`, `vim.fn.getchar`, `vim.fn.confirm`, `vim.ui.select`, or `vim.ui.input`
appears anywhere in the wizard code path.

#### Scenario: grep-as-test guards the wizard

- **WHEN** the no-blocking-prompt test scans the wizard modules
- **THEN** it passes only when none of the banned blocking-prompt calls are present in
  the wizard path, while allowing `vim.ui.select` in the random-access `:Bean <field>`
  path outside the wizard
