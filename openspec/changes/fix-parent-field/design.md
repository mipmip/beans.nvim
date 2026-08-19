## Context

The `parent` step was implemented as an insert-mode filter prompt: on entry it calls
`startinsert`, renders an editable prompt line, and binds `<CR>` / `<C-n>` / `<C-p>`
in insert mode, tracking the highlighted candidate in `state.parent.cursor`. Two
assumptions in that design are wrong in practice, and the default candidate types are
too broad.

## Goals / Non-Goals

**Goals:**
- The parent card always reflects the parent step only (no stale content).
- Parent selection works with plain normal-mode editing (`j`/`k` + `<CR>`), which is
  how users actually drive the picker, while typing-to-filter still works.
- Default parent candidates are milestones and epics.

**Non-Goals:**
- Removing the type-to-filter capability (it stays; it just no longer depends on
  insert mode having been entered, and it no longer seeds from stale buffer text).
- Changing the tags step or the enum steps.

## Decisions

- **Empty query on entry (bug 1).** `parent.enter` must initialise its query from an
  explicit state field (default `""`), not from `query()` reading the float buffer.
  The root cause is that `draw()` set `prompt = query()`, and `query()` reads float
  line 2 — which still held the previous step's `[ ] core` render because the parent
  render had not yet overwritten it. Track the query in `state.parent.query` and drive
  `refilter` from it; the prompt line is a *display* of that state, and the
  `TextChangedI` handler updates `state.parent.query` from the buffer only while the
  user is actually typing.

- **Normal-mode operation, cursor-based selection (bug 2).** Bind `<CR>`, `j`/`k`,
  `<C-n>`/`<C-p>` in normal mode on the float. Selection resolves the candidate from
  the cursor's line (map buffer line → candidate via the render's option offset),
  rather than only from an internal index moved by insert-mode maps. Do not rely on
  `startinsert` succeeding. Typing-to-filter can be offered via a dedicated key that
  opens the editable prompt line, or by keeping the prompt line editable while also
  honouring normal-mode motion — but the DoD is that `j`/`k` + `<CR>` alone select a
  candidate. Keep the "no blocking prompt" rule (§11.0): all input stays on
  buffer-local keymaps of the float buffer.

- **Default types milestone + epic (bug 3).** Change `config.defaults.fields.parent.types`
  to `{ "milestone", "epic" }`. `nil` continues to mean "offer every type"; a
  user-supplied list overrides. Beans of other types are excluded by default.

## Risks / Trade-offs

- Moving selection to cursor-line resolution means the render layout (title, prompt,
  options, footer) and the option offset must stay in sync with the cursor mapping;
  covered by a layer-2 spec that selects in normal mode and asserts the written parent.
- Reconciling normal-mode motion with an editable filter line needs care so the two
  interaction modes do not fight; the tests lock the normal-mode path as the contract.
