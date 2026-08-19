## 1. unit-wizard-tests (beans.nvim-viwn)

- [ ] 1.1 Write `tests/minimal_init.lua` that puts the plugin and `plenary.nvim` on
      `runtimepath` and prepends `tests/fixtures/` to `PATH`.
- [ ] 1.2 Write the executable `tests/fixtures/fake-beans` stub emitting canned
      `beans update --help`, `beans list --json`, and `beans show <id> --json`.
- [ ] 1.3 Write `tests/helpers/project.lua` to build a temp Beans project on disk
      (`.beans.yml` + sample bean files under `tests/fixtures/beans/`).
- [ ] 1.4 Write `tests/helpers/child.lua` to spawn and drive a child nvim over RPC.
- [ ] 1.5 Write `frontmatter_spec.lua` covering every §11.1(1) case: replace, insert
      at each canonical gap, clear, tag write/clear, comment/`created_at`/`updated_at`/
      `order` preservation, tricky titles, and byte-identical no-op.
- [ ] 1.6 Write `schema_spec.lua`: help parsing incl. the `or empty to clear` tail,
      fallback on parse-failure/missing binary, mnemonics incl. forced digit fallthrough.
- [ ] 1.7 Write `project_spec.lua` and `detect_spec.lua`: nested-dir root detection,
      custom `beans.path`, `archive/` files, and the negative (plain markdown attaches
      nothing — `vim.b.beans == nil`, no plugin keymap).
- [ ] 1.8 Write `config_spec.lua`: no-arg setup, partial-merge keeps siblings, invalid
      value warns once and falls back.
- [ ] 1.9 Write the auto-start heuristic specs (fires on fresh empty bean; not on old/
      bodied/disabled).
- [ ] 1.10 Write `wizard_spec.lua` (layer 2): sequencing, mnemonic apply+advance,
      `<S-Tab>` restore, unchanged-`<Tab>` no dirty, `<Esc>` from every step,
      five-apply/five-undo == original, finish state (mode `i`, last body line), tags
      toggle/new, parent filter + self-exclusion.
- [ ] 1.11 Write the grep-as-test asserting no `vim.fn.input`/`getchar`/`confirm`/
      `vim.ui.select`/`vim.ui.input` in the wizard path.
- [ ] 1.12 Confirm layers 1-2 pass headless via `PlenaryBustedDirectory tests/`.

## 2. golden-equivalence (beans.nvim-2y8q)

- [ ] 2.1 Verify the exact indentation Beans emits for a `tags:` block sequence by
      running `beans update <id> --tag foo` in a scratch project (briefing §14.1).
- [ ] 2.2 Build the scenario matrix: set status/type/priority, clear priority, add
      one/three tags, remove a tag, remove all tags, set/clear parent, title-with-colon
      — each against a fully-populated and a minimal bean.
- [ ] 2.3 Implement `golden_spec.lua`: create bean → copy to `A.md`/`B.md` → apply via
      `beans update` (A) and `frontmatter.lua` (B) → assert byte-identical modulo
      `updated_at`.
- [ ] 2.4 Generate and commit `tests/fixtures/golden/` so the matrix runs without a
      `beans` binary.
- [ ] 2.5 Add the scheduled golden-regeneration CI job that regenerates against the
      latest Beans release and fails on any diff.

## 3. e2e-ci-release (beans.nvim-angp)

- [ ] 3.1 Implement `e2e_spec.lua` spawning a child nvim (`--embed --headless`) over
      RPC with the plugin on `runtimepath` and a temp Beans project.
- [ ] 3.2 Implement the canonical §11.4 scenario driven by `nvim_input`: TUI-style
      bean → assert float exists → `i` `b` `h` → `<Tab>` `<Tab>` → assert mode `i`,
      cursor on last body line, no float → `<Esc>` `:w<CR>` → assert file parses and
      `beans show <id> --json` reports the three values.
- [ ] 3.3 Implement the negative scenario: plain markdown outside a project → no float,
      `vim.b.beans == nil`, `<leader>bw` no-op.
- [ ] 3.4 Add `.github/workflows/` CI running inside `nix develop`: `stylua --check`
      then layers 1-4 headless.
- [ ] 3.5 Extend the CI matrix to the nixvim-pinned Neovim plus stable and nightly.
- [ ] 3.6 Write `tests/MANUAL.md` layer-5 checklist (briefing §11.5).
- [ ] 3.7 Complete `README.md`: install, wizard flow, keymaps, config, and the
      letter-select vs filter-select inconsistency.
- [ ] 3.8 Complete `doc/beans.txt` vimdoc.

## 4. Definition of Done

- [ ] 4.1 Opening a bean created by the Beans TUI auto-starts the wizard.
- [ ] 4.2 `status`, `type`, `priority` each set with one keystroke, auto-advancing.
- [ ] 4.3 Tags multi-select with toggle, new-tag entry, and validation.
- [ ] 4.4 Parent selection filtered by typing, self excluded, clearable.
- [ ] 4.5 `<S-Tab>` goes back; `<Esc>` finishes from any step.
- [ ] 4.6 Finishing leaves the cursor in the body in insert mode.
- [ ] 4.7 Each field change is one undo step; five undos restore the original file.
- [ ] 4.8 Missing optional keys are inserted in canonical order.
- [ ] 4.9 Saving produces a file byte-identical to `beans update` output (verified by
      the layer-3 golden matrix).
- [ ] 4.10 A plain markdown file outside a Beans project gets no keymaps, autocmds, or
      popups.
- [ ] 4.11 `:checkhealth beans` explains any detection failure.
- [ ] 4.12 `setup()` with no arguments yields the full experience; a partial config
      merges without wiping siblings; an invalid value warns once and falls back.
- [ ] 4.13 No blocking prompt exists anywhere in the wizard path (grep-as-test).
- [ ] 4.14 The layer-3 golden matrix passes byte-identically.
- [ ] 4.15 The layer-4 e2e scenario passes end to end, incl. `beans show --json`
      confirmation.
- [ ] 4.16 `nix develop` gives a working isolated nvim with `beans` available; tests
      pass headless in CI.
- [ ] 4.17 README covers install, wizard flow, keymaps, config, and the deliberate
      letter-select vs filter-select inconsistency.
