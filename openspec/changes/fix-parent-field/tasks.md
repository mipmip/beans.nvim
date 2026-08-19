## 1. Empty query on entry (beans.nvim-943x)

- [ ] 1.1 Track the parent filter query in `state.parent.query` (default `""`); render
  the prompt line from that state, not from `query()` reading the float buffer.
- [ ] 1.2 Update the `TextChangedI`/typing handler to write `state.parent.query` from the
  buffer only while the user is typing, then refilter from state.
- [ ] 1.3 Layer-2 spec: full tags→parent transition leaves no stale line (the parent
  card shows only candidates + clear, prompt empty).

## 2. Normal-mode, cursor-based selection (beans.nvim-0v6n)

- [ ] 2.1 Bind `<CR>`, `j`/`k`, `<C-n>`/`<C-p>` in normal mode on the float; do not rely
  on `startinsert` succeeding.
- [ ] 2.2 Resolve the selected candidate from the cursor line (buffer line → candidate via
  the render's option offset), not only from an internal index.
- [ ] 2.3 Keep type-to-filter working without a blocking prompt (§11.0).
- [ ] 2.4 Layer-2 spec: normal-mode `j`/`k` + `<CR>` selects the candidate under the cursor
  and writes `parent`; verify it works via `:Bean parent` / `<leader>bP` as well.

## 3. Milestones and epics only (beans.nvim-jql2)

- [ ] 3.1 Change `config.defaults.fields.parent.types` to `{ "milestone", "epic" }`.
- [ ] 3.2 Confirm `nil` still offers every type and a custom list overrides.
- [ ] 3.3 Spec/tests: default candidate list excludes features; update README /
  briefing §7.3 note.

## 4. Verification

- [ ] 4.1 `nix develop` full suite green (`scripts/test.sh tests/`), stylua clean.
- [ ] 4.2 Manually confirm in `nix develop` that the parent step renders candidates,
  selects in normal mode, and lists milestones/epics only.
