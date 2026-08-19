## Why

The data layer and wizard give beans.nvim its mechanics, but a plugin is only as
good as the surface a user actually touches. Milestone 04 delivers that surface: a
`setup()` that produces the full intended experience with zero arguments, the
commands and buffer-local keymaps that launch the wizard and random-access field
edits, and an opt-in insert-mode completion that helps without fighting other
plugins. Without this milestone the wizard exists but cannot be configured, invoked
by name, or complemented by frontmatter-aware completion.

## What Changes

- Add a configuration system (`config.lua`): the complete default table (briefing
  §7.3), deep-merge of partial user tables, and validate-on-setup that warns once
  and falls back per offending key rather than erroring.
- Add commands and keymaps: `:BeanWizard`, `:Bean` (field menu → value picker),
  `:Bean <field>` (jump straight to one field, completes on field names), and full
  `:checkhealth beans` diagnostics. Buffer-local keymaps of §7.2, all disable-able
  and individually overridable, plus `on_attach`/`on_finish` hooks.
- Add random-access field editing (`actions.lua`): reuse the buffer-edit code path
  when the bean is open in a buffer; fall back to `beans update` only for a bean not
  currently open.
- Add opt-in insert-mode completion (`completion.lua`): a zero-dependency omnifunc
  active only inside frontmatter after known keys, plus optional `blink.cmp` and
  `nvim-cmp` sources behind config flags (default off, lazily required).

## Capabilities

### New Capabilities
- `configuration`: The `setup()` contract — defaults, deep merge of partial tables,
  and non-fatal validation with per-key fallback.
- `commands-keymaps`: User commands, buffer-local keymaps, random-access field
  editing, lifecycle hooks, and `:checkhealth beans` diagnostics.
- `insert-completion`: Opt-in frontmatter-aware insert-mode completion via omnifunc
  and optional cmp/blink sources.

## Impact

- New modules: `lua/beans/config.lua`, `lua/beans/actions.lua`,
  `lua/beans/completion.lua`, `lua/beans/health.lua`; command/keymap wiring in
  `lua/beans/init.lua`.
- Consumes the data layer (`schema.lua`, `frontmatter.lua`, `detect.lua`,
  `project.lua`) and the wizard (`wizard/init.lua`).
- Optional integrations with `blink.cmp` and `nvim-cmp` remain soft dependencies —
  never required, always lazily loaded.
- Test surface: `config_spec.lua` (§11.1) covering merge and validation behaviour.
