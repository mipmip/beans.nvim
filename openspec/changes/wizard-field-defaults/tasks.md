## 1. Configuration surface

- [x] 1.1 Add a `default` key (unset) to the `fields.status`, `fields.type` and
  `fields.priority` entries of the default table in `lua/beans/config.lua`, creating
  the `status` and `type` entries which do not exist yet; verify with a
  `tests/config_spec.lua` case asserting that zero-argument setup leaves all three
  defaults nil and that `fields.priority.allow_clear` is still true
- [x] 1.2 Extend `config.validate` to drop a non-string `fields.<field>.default` with
  one warning naming the key, leaving a string value untouched whatever it contains;
  verify with `tests/config_spec.lua` cases for a number (dropped, one warning) and
  for a string absent from every vocabulary (kept, no warning)
- [x] 1.3 Add a `tests/config_spec.lua` case passing only `fields.priority.default`
  and asserting that `fields.priority.allow_clear`, `fields.tags` and `fields.parent`
  keep their defaults, covering the deep-merge requirement

## 2. Shared notification gate

- [x] 2.1 Extract the notify-level gate currently inline in `setup` in
  `lua/beans/init.lua` into a helper that takes a config and a message and emits at
  most one `vim.notify` at WARN, honouring `notify = false` and a numeric threshold;
  verify by asserting the existing setup-validation warning tests still pass unchanged
- [x] 2.2 Point `setup` at the new helper and confirm no behaviour change; verify with
  the existing `notify = false` case in `tests/config_spec.lua`

## 3. Warn-once record

- [x] 3.1 Add a per-root, per-field record of defaults already warned about alongside
  the existing per-root caches in `lua/beans/schema.lua`, with a reset entry point for
  tests; verify with a `tests/schema_spec.lua` case asserting that the second query for
  the same root and field reports already-warned and that a different root does not
- [x] 3.2 Make the record participate in whatever the test suite already uses to clear
  `_vocab_cache` and `_list_cache` between cases, so no test leaks state into the next

## 4. Cursor placement in the enum step

- [x] 4.1 In `lua/beans/wizard/steps/enum.lua`, capture whether the current-value
  lookup returned nil as a distinct signal from the absence of an active option, so a
  set-but-unrecognised value can be told apart from an unset field; verify with a
  `tests/wizard_spec.lua` case on a bean reading `priority: urgent` asserting no
  option is active and the cursor is on option 1 with a default configured
- [x] 4.2 When the field is unset and `fields.<field>.default` names an option in the
  list, start the cursor on that option instead of option 1; verify with a
  `tests/wizard_spec.lua` case on a bean with no `priority:` key asserting the cursor
  is on `normal`
- [x] 4.3 Assert the buffer is untouched by opening the step: add a
  `tests/wizard_spec.lua` case comparing buffer lines before and after entering the
  priority step with a default configured
- [x] 4.4 Add `tests/wizard_spec.lua` cases for the two confirm paths on an unset field
  with a default: the next key advances and adds no `priority:` key, the select key
  writes `priority: normal` and advances
- [x] 4.5 Add a `tests/wizard_spec.lua` case asserting that a bean reading
  `priority: high` puts the cursor on `high` with `fields.priority.default` set to
  `normal`, confirming the set value wins
- [x] 4.6 Add a `tests/wizard_spec.lua` case asserting that with no default configured
  the cursor starts on option 1, confirming the unchanged path

## 5. Vocabulary mismatch warning

- [x] 5.1 Warn when the field is unset, a default is configured, the field's
  vocabulary resolved from the CLI, and the value is absent from it; the message names
  the field, the configured value and the accepted values, and the cursor falls back
  to option 1; verify with a `tests/wizard_spec.lua` case configuring
  `fields.priority.default` as `urgent`
- [x] 5.2 Gate the check on the per-field vocabulary entry rather than on the
  vocabulary table, so the no-project-root case and the pre-resolution render stay
  silent; verify with `tests/wizard_spec.lua` cases rendering the step before the
  vocabulary lands and on a buffer with no project root, both asserting no warning
- [x] 5.3 Consult and set the warn-once record so re-entry emits nothing further;
  verify with a `tests/wizard_spec.lua` case that enters the step, navigates back to
  it and re-renders it, asserting exactly one warning
- [x] 5.4 Route the warning through the helper from task 2.1; verify with a
  `tests/wizard_spec.lua` case configuring `notify = false` alongside an unknown
  default and asserting no notification and a cursor on option 1

## 6. Fixtures and suite

- [x] 6.1 Add or adjust a bean fixture with no `priority:` key, matching what
  `beans create` actually writes, for the unset-field cases; verify by asserting the
  fixture's frontmatter has status and type but no priority
  (done as the inline `NO_PRIORITY` fixture in `tests/wizard_spec.lua`; the shared
  `tests/fixtures/beans/` directory is empty and unreferenced, so no file was added)
- [x] 6.2 Run the full headless suite and `stylua --check`, and confirm the
  no-blocking-prompt grep test still passes given no new prompt was introduced

## 7. Documentation

- [x] 7.1 Document `fields.<field>.default` in the configuration section of
  `README.md`, stating plainly that it positions the cursor and that the value is
  confirmed rather than applied, so the next key still leaves the field unset; verify
  by reading the rendered section
- [x] 7.2 Mirror the same text into `doc/beans.txt` and regenerate tags if the build
  does so; verify with `:help` on the new key in the dev nvim
- [x] 7.3 Note in the documentation that tags and parent take no default and why;
  verify by reading the rendered section
