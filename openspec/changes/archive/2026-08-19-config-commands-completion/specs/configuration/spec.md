## ADDED Requirements

### Requirement: Zero-argument setup yields the full experience

`require("beans").setup()` called with no arguments SHALL produce the complete
intended experience described in the briefing, using the default configuration
table (§7.3) for every value. No configuration SHALL be required to get detection,
auto-start, the wizard, commands, and keymaps.

#### Scenario: setup with no arguments
- **WHEN** a user calls `require("beans").setup()` with no arguments
- **THEN** the plugin loads with all defaults active
- **AND** opening a freshly-created bean auto-starts the wizard with all five steps

#### Scenario: setup with an empty table
- **WHEN** a user calls `require("beans").setup({})`
- **THEN** the resulting effective config is identical to the full default table

### Requirement: Partial configuration merges without wiping siblings

The plugin SHALL merge a user-supplied partial config into the defaults using a deep
merge so that setting one nested key preserves all sibling defaults.

#### Scenario: overriding one keymap keeps the others
- **WHEN** a user passes `{ keymaps = { wizard = "<leader>zz" } }`
- **THEN** `keymaps.wizard` is `<leader>zz`
- **AND** `keymaps.menu` and every `keymaps.fields.*` entry retain their defaults

#### Scenario: overriding one nested wizard option
- **WHEN** a user passes `{ wizard = { autostart = { enabled = false } } }`
- **THEN** `wizard.autostart.enabled` is `false`
- **AND** `wizard.autostart.max_age_seconds` and `wizard.fields` retain their defaults

### Requirement: Invalid configuration warns once and falls back

Validation SHALL run on setup. For each invalid value the plugin SHALL emit at most
one `vim.notify` message naming the offending key, then substitute that key's
default. `setup()` SHALL NOT raise an error for any invalid configuration.

#### Scenario: invalid value falls back to default
- **WHEN** a user passes a value of the wrong type for a known key
- **THEN** `setup()` returns without error
- **AND** the effective value for that key is its default
- **AND** exactly one notification names the offending key and the fallback used

#### Scenario: notifications respect the notify setting
- **WHEN** a user passes `{ notify = false }` together with an invalid value
- **THEN** `setup()` returns without error and no notification is emitted

### Requirement: Setup tolerates a missing beans binary

`setup()` SHALL complete successfully when the `beans` executable is absent from
`$PATH`, degrading only to a `:checkhealth beans` warning rather than an error.

#### Scenario: beans not installed
- **WHEN** `beans` is not on `$PATH` and a user calls `setup()`
- **THEN** `setup()` returns without error
- **AND** the plugin still loads for detection and buffer editing
