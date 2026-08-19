## Context

The data layer (Milestone 02) and wizard (Milestone 03) are in place. This
milestone wraps them in the user-facing surface: configuration, commands, keymaps,
and completion. The guiding constraint from the briefing (§7.3) is that the default
experience must be excellent with no configuration at all, and that a misconfigured
plugin must still load. Everything here is buffer-local to bean buffers except the
`setup()` entry point; non-bean markdown must remain untouched (briefing §6).

## Goals / Non-Goals

**Goals:**
- `setup()` with no arguments yields the full intended experience (briefing §1, §7.3).
- Partial user config merges without wiping sibling defaults.
- Invalid config values warn once and fall back rather than erroring.
- Commands, keymaps, hooks, and `:checkhealth beans` are wired and self-diagnosing.
- Random-access field editing reuses the wizard's buffer-edit code path when possible.
- Insert-mode completion is opt-in, dependency-free by default, and never collides
  with other completion plugins.

**Non-Goals:**
- A bean browser/picker over all beans (briefing §13 non-goal).
- Creating beans from within nvim; statusline components; live `beans serve` sync.
- Making the canonical frontmatter order, buffer-vs-CLI strategy, or `# <id>`
  handling configurable (briefing §7.3 "Deliberately not configurable").

## Decisions

- **Zero-arg `setup()` is the product.** Every default in the §7.3 table is the
  recommended value. Nobody should need to configure anything to get the experience
  in §1. The default table lives in `config.lua` and doubles as the spec for defaults.
- **Deep merge with `vim.tbl_deep_extend("force", defaults, user)`.** Setting one
  keymap must not wipe the others; partial tables always merge into full defaults.
- **Validate on setup, never error.** Each offending key is reported once via
  `vim.notify` (respecting the `notify` level, or silenced when `notify = false`),
  then the default for that key is substituted. `setup()` returns normally even with
  a bad config. `setup()` must also not error when `beans` is missing from `$PATH` —
  that degrades to a `:checkhealth` warning only.
- **Random-access editing prefers the buffer.** `:Bean <field>` and the `:Bean` menu
  use the same buffer-edit code path as the wizard when the target bean is open in a
  buffer (native undo, no disk write until `:w`). Only when acting on a bean that is
  not currently open does `actions.lua` fall back to `beans update`.
- **`vim.ui.select` is allowed only outside the wizard.** The random-access path may
  use `vim.ui.select`/`vim.ui.input` (stubbable in tests); the wizard itself must
  never use them or any blocking prompt (briefing §11.0). This keeps the wizard
  testable while giving random-access a familiar picker.
- **No insert-mode `<Tab>`/`<CR>` mappings.** They collide with every completion
  plugin. The only insert-mode moment the plugin owns is `startinsert` at wizard
  finish. Completion is exposed purely through `omnifunc` and optional sources.
- **Optional sources are lazily required.** `blink.cmp` and `nvim-cmp` sources are
  registered only when their config flags are true and only `require`d at that point,
  so neither is ever a hard dependency; an absent plugin causes no error.
- **Commands and keymaps are buffer-local.** They attach on bean detection via the
  `beans.nvim` augroup and never appear in non-bean buffers. `keymaps.enabled =
  false` disables all; individual entries are overridable; a keymap set to a value
  false unbinds just that one.

## Risks / Trade-offs

- **Deep-merge of list-valued keys** (e.g. `wizard.keys.finish = { "<Esc>", "q" }`)
  can surprise users who expect replacement, not merge. Mitigation: document list
  semantics and treat multi-key values as replace-the-list at the leaf.
- **Silent fallback can mask typos.** Mitigation: the one-time `vim.notify` names the
  offending key and the value used instead; `:checkhealth beans` reports config state.
- **Omnifunc context detection** (only inside frontmatter, after known keys) risks
  false negatives that feel like "completion doesn't work." Mitigation: keep the
  gate narrow and well-tested; outside the gate, return nothing so the user's normal
  completion still works.
- **`vim.ui.select` in random-access** depends on whatever picker the user installed.
  Accepted: it is outside the wizard, and tests stub it directly.
