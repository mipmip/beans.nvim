## 1. wizard-core (beans.nvim-bsoh)

- [ ] 1.1 Create `lua/beans/wizard/init.lua`: state machine driving the configured
  `fields` order, holding per-step picks and the as-opened buffer snapshot.
- [ ] 1.2 Create `lua/beans/wizard/ui.lua`: near-cursor float with title+progress
  (`2/5 · type`), option list, and key-hints footer; open/redraw/close helpers.
- [ ] 1.3 Wire universal keys (§4.3): next (accept+advance), prev (`<S-Tab>` back one
  step, restoring the prior pick highlighted), select, finish (`<Esc>`/`q`), abort
  (`<C-c>`). Advancing past the last step finishes.
- [ ] 1.4 Apply each field via `frontmatter.lua` in a single `nvim_buf_set_lines` call so
  each field is exactly one undo step (§4.4, §5.2).
- [ ] 1.5 On step activation, move the cursor to the field's frontmatter line (or its
  insertion point) and highlight it; flash the changed text after applying (§4.1).
- [ ] 1.6 Finish behaviour: close float, position cursor per `finish.cursor` (default
  first body line, never the closing `---`), `startinsert` when configured (§4.3).
- [ ] 1.7 Auto-start heuristic (§6.1): fire only when recognised bean + `created_at`
  within `max_age_seconds` + empty body; guard behind `autostart.enabled`.
- [ ] 1.8 Loading state for steps whose prefetch has not landed; never `vim.system():wait()`
  on the main loop (§5.3).
- [ ] 1.9 Define highlight groups (§7.4), each linking to a standard group by default.
- [ ] 1.10 Register `:BeanWizard` and the `<leader>bw` mapping to start at step 1.
- [ ] 1.11 Grep-as-test guard: assert no `vim.fn.input`/`getchar`/`confirm`/`vim.ui.select`/
  `vim.ui.input` under `lua/beans/wizard/` (§11.0).

## 2. wizard-enum-steps (beans.nvim-cqc9)

- [ ] 2.1 Create `lua/beans/wizard/steps/enum.lua` handling `status`/`type`/`priority`.
- [ ] 2.2 Render options with dynamically assigned mnemonics from the discovered vocab
  (first letter → next unused letter → digits `1..9`), honouring configured overrides.
- [ ] 2.3 Press-the-letter = select + confirm + auto-advance (one keystroke per field).
- [ ] 2.4 Mark the currently-set value (`BeansWizardActive`) and show hints
  (`BeansWizardHint`) beside each option.
- [ ] 2.5 `priority` clear entry when `allow_clear` is set: remove the line; `status`/`type`
  offer no clear entry.

## 3. wizard-tags-parent (beans.nvim-udyu)

- [ ] 3.1 Create `lua/beans/wizard/steps/tags.lua`: checkbox list over the tag universe;
  `j`/`k` move, `<Space>` toggle, `<CR>`/`<Tab>` confirm+advance (no auto-advance on toggle).
- [ ] 3.2 New-tag entry (`n`) as an editable prompt line inside the wizard buffer (NOT
  `vim.fn.input`); normalise + validate against `^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$`, reject
  invalid with a message.
- [ ] 3.3 Create `lua/beans/wizard/steps/parent.lua`: filter-as-you-type via
  `vim.fn.matchfuzzy` over `"<id> <title>"`; `<C-n>`/`<C-p>` or `j`/`k` move.
- [ ] 3.4 `<CR>` selects+advances; `x` clears an existing parent; restrict candidates to the
  configured types and always exclude the bean itself.
- [ ] 3.5 Sort candidates per `fields.parent.sort`.

## 4. Layer-2 in-process wizard specs (§11.2)

- [ ] 4.1 Create `tests/wizard_spec.lua` driving the real wizard against a real buffer with
  `nvim_api_feedkeys(keys, "x", false)`.
- [ ] 4.2 Cover: step sequencing; mnemonic keypress applies+advances; `<S-Tab>` returns with
  the previous pick highlighted; `<Tab>` on an unchanged field advances without dirtying the
  buffer; `<Esc>` exits from every step.
- [ ] 4.3 Cover one-undo-step-per-field: apply five fields, press `u` five times, assert the
  buffer matches the original exactly.
- [ ] 4.4 Cover finish state: cursor on the last body line, mode is insert, no float remains.
- [ ] 4.5 Cover tags toggle/new-tag/validation-reject, and parent filter narrowing +
  self-exclusion + clear.
- [ ] 4.6 Add the grep-as-test for blocking prompts (§11.0) to the spec suite.
