## Why

Beans fills `status` and `type` on a new bean from `.beans.yml` (`default_status`,
`default_type`), but it has no `default_priority`. A freshly created bean therefore
arrives with no `priority:` key at all, and the wizard's priority step starts its
cursor on the first option in the vocabulary, which is `critical`. The most alarming
value in the list sits under the cursor on the one field Beans leaves empty.

Users should be able to say "when this field is unset, start me on `normal`" without
the plugin writing anything they did not choose.

## What Changes

- Add `fields.<field>.default` for the enum steps `status`, `type` and `priority`.
  When the field is unset on the bean, the step opens with the cursor on the
  configured value instead of on the first option.
- The default is **cursor placement only**. Nothing is written to the buffer until
  the user confirms with `<CR>` or a mnemonic. `<Tab>` still advances without
  writing, so opening the wizard remains a non-mutating act.
- The default applies only when the field has no value in the frontmatter. A field
  set to a value outside the discovered vocabulary counts as set and is left alone.
- A configured default that is not in the discovered vocabulary emits one warning
  per project root per field and falls back to today's behaviour (cursor on the
  first option). The warning is raised only against a vocabulary that actually
  resolved from `beans update --help`, never against the `fallback` table, so a
  project with a customised vocabulary does not see a spurious warning on the
  first wizard of a session.
- `config.validate` gains a setup-time type check that each `fields.<field>.default`
  is a string, warning once and dropping the key when it is not.
- Not in scope: defaults for `tags` and `parent`. In those steps `<Tab>` is bound to
  confirm-and-write rather than skip, so a pre-selected default would be written by
  the key that means "I chose nothing". Resolving that asymmetry is separate work.

No breaking changes. Every new key defaults to `nil`, so an existing configuration
behaves exactly as it does today.

## Capabilities

### New Capabilities

None. This extends two existing capabilities.

### Modified Capabilities

- `wizard-enum-steps`: initial cursor placement gains a configured fallback for an
  unset field, plus the vocabulary-mismatch warning and its warn-once scope.
- `configuration`: the default config table gains `fields.status.default`,
  `fields.type.default` and `fields.priority.default`, and setup-time validation
  covers their type.

## Impact

- `lua/beans/wizard/steps/enum.lua`: the cursor-initialisation block that currently
  scans for the active option.
- `lua/beans/config.lua`: the `fields` entries in `M.defaults`, and `M.validate`.
- `lua/beans/init.lua`: the `vim.notify` level gate at setup is duplicated logic once
  the wizard also needs it; extract it into a shared helper.
- `lua/beans/schema.lua` or the wizard: a per-root warn-once record, alongside the
  existing per-root caches.
- Tests: unit coverage in the enum-step and configuration suites, plus an in-process
  wizard test asserting the cursor position and that the buffer is untouched.
- Docs: the configuration section of `README.md` and `doc/beans.txt`.
