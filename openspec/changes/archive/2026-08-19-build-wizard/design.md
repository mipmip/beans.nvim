## Context

By the time the wizard runs, Milestone 02 has already: detected the bean and set
`vim.b.beans = { id, root, beans_dir, bufnr }`; discovered the field vocabularies and
computed mnemonics (`schema.lua`); prefetched the tag universe and parent candidates
(`beans list --json`); and provided a pure, tested frontmatter editor (`frontmatter.lua`)
that turns a "set field X to Y" request into a single `nvim_buf_set_lines` call in
canonical key order.

The wizard is the interactive layer on top. It is spawned in one of two ways: manually
via `:BeanWizard`/`<leader>bw`, or automatically when the Beans TUI has just created a
bean and opened it in this editor (briefing §6.1). The TUI is blocked waiting for the
editor to exit, holding the real file open — this is precisely why the wizard edits the
buffer and lets `:w` be the only thing that touches disk (briefing §5).

## Goals / Non-Goals

**Goals:**
- Make well-formed metadata entry feel instant: one keystroke per enum field, visible
  document mutation, native undo.
- Unify three genuinely different interaction models in one coherent flow.
- Be completely testable in-process: every keystroke goes through buffer-local keymaps
  so `nvim_api_feedkeys(keys, "x", false)` runs synchronously (briefing §11.2).
- Zero footprint when it should not run (old bean, non-empty body, non-bean markdown).

**Non-Goals:**
- Editing existing beans outside the freshly-created flow (random-access `:Bean <field>`
  lands in Milestone 04; it may reuse the buffer-edit path).
- Shelling out to `beans update` during the wizard (explicitly forbidden, briefing §5).
- A bean browser/picker, statusline, or live `beans serve` integration (v1 non-goals).

## Decisions

### Buffer edits, not the CLI (briefing §5)
Every field change is applied by calling `frontmatter.lua` and writing the result with a
single `nvim_buf_set_lines` per field. Rationale: the TUI already holds the real file and
is blocked on the editor; a concurrent `beans update` would rewrite the file under a
possibly-modified buffer. Buffer edits also give native undo for free and keep per-field
latency at zero. The CLI stays the source of truth for reads only.

### One undo step per field (briefing §4.4, §5.2)
Each applied change is exactly one `nvim_buf_set_lines` call, so `u` walks back through
the picks one at a time. Applying five fields then pressing `u` five times must restore
the buffer to its as-opened bytes. This is asserted directly in the layer-2 specs.

### Three interaction modes, one flow (briefing §4.2) — the hard part
The field kinds cannot share one interaction model, and pretending otherwise is worse
than admitting it. The state machine owns sequencing and universal keys; each step module
owns its own selection model and returns control to the machine on advance.

- **Enum steps** (`status`, `type`, `priority`): the keypress *is* both selection and
  confirmation. Press the mnemonic letter → apply → auto-advance. Mnemonics are computed
  from the discovered vocabulary (first letter, then next unused letter in the word, then
  digits `1..9`); never hardcoded. `priority` additionally offers a "clear" entry.
- **Tags step**: multi-select cannot auto-advance on keypress. Checkboxes over the tag
  universe; `j`/`k` move, `<Space>` toggles, `<CR>`/`<Tab>` confirm and advance.
- **Parent step**: the candidate list is long, so mnemonics are useless. Typing filters
  via `vim.fn.matchfuzzy` over `"<id> <title>"`; `<CR>` selects, `x` clears.

The README must document this inconsistency rather than hide it (briefing §4.2).

### No blocking prompts anywhere (briefing §11.0) — a hard constraint from testability
The wizard must never call `vim.fn.input()`, `vim.fn.confirm()`, `vim.fn.getchar()`, or
`vim.ui.select`/`vim.ui.input`. They halt the event loop, cannot be driven by
`nvim_feedkeys`, and would force the whole flow into manual QA. Consequences baked into
the design:
- The tags step's "new tag" entry (`n`) and the parent step's filter input are
  implemented as an **editable prompt line inside the wizard buffer**, not a
  `vim.fn.input()` call. Keystrokes are captured via buffer-local insert-mode maps (or a
  small character-collection loop over mapped keys) on the wizard buffer, never a modal
  prompt.
- A grep-as-test asserts none of the forbidden calls appear in `lua/beans/wizard/`.

### `<Esc>` finishes, it does not step back (briefing §4.3)
Esc-as-back is surprising, and the overwhelmingly common case is "defaults are fine, let
me write." `<Esc>`/`q`/`<C-c>` finish the wizard entirely. Finishing (by `<Esc>` or by
advancing past the last step) closes the float, moves the cursor per `finish.cursor`
(default `body_end`), and calls `startinsert` — landing on the first body line, never on
the closing `---`. `<S-Tab>` is the only back-navigation and re-enters a step with the
previously-picked value highlighted, so `<S-Tab>` then `<Tab>` is a no-op.

### Show the document changing (briefing §4.1)
As each step activates, move the cursor to that field's line in the buffer (or where the
line will be inserted) and highlight it (`BeansFieldLine`). When a value is applied, flash
the changed text briefly (`BeansFlash`). The user must see the file mutating rather than
trusting a modal.

### Auto-start heuristic (briefing §6.1)
Auto-start fires only when **all** hold: the buffer is a recognised bean; `created_at` is
within `autostart.max_age_seconds` (default 30) of now; and the body is empty/whitespace.
This distinguishes "the TUI just made this" from "I opened an old bean" without process
detection. It must be one flag to disable, and `<Esc>` must always be an instant exit.

### Highlight groups (briefing §7.4)
`BeansWizardTitle`→`Title`, `BeansWizardKey`→`Special`, `BeansWizardCurrent`→`CursorLine`,
`BeansWizardActive`→`DiagnosticOk`, `BeansWizardHint`→`Comment`, `BeansFieldLine`→`Visual`,
`BeansFlash`→`IncSearch`. All default to `links` so any colorscheme works untouched.

## Risks / Trade-offs

- **Editable prompt line vs. `vim.fn.input`**: hand-rolling an in-buffer prompt is more
  code than a one-line `input()` call, but it is the only testable and themable option,
  and it keeps `<Esc>` behaviour uniform. Accepted.
- **Auto-start false positives/negatives**: the 30s + empty-body heuristic can misfire at
  the edges. Mitigated by making it one flag to disable and `<Esc>` an instant exit
  (briefing §6.1). Auto-opening a modal is delightful when correct and enraging when
  wrong, so both escape hatches are mandatory.
- **Prefetch not yet landed when a step is reached**: steps 4/5 depend on `beans list`.
  If data has not arrived, render a "loading…" state that replaces itself when the data
  lands; never `vim.system():wait()` on the main loop (briefing §5.3).
- **Undo grouping fragility**: multiple `nvim_buf_set_lines` calls per field would split
  a change across undo steps. Enforced by a single call per field and covered by the
  five-undo restore test.
