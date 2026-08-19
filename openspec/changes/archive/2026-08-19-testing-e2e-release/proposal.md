## Why

A plugin that edits a file the Beans TUI is blocking on cannot ship on hope: the
buffer-editing decision (write frontmatter directly, never shell out to `beans
update` while the file is open) is only safe if we can prove the bytes we write are
the bytes Beans would have written. This milestone builds the automated proof —
five test layers that gate CI — plus the docs and Definition-of-Done sign-off that
make the PoC a credible alpha base.

## What Changes

- Add a hermetic unit + in-process wizard test harness: `tests/minimal_init.lua`, a
  `tests/fixtures/fake-beans` stub on `PATH` emitting canned `--help`/JSON,
  `helpers/project.lua` (temp Beans project) and `helpers/child.lua` (RPC child nvim).
- Add layer-1 unit specs (`frontmatter_spec`, `schema_spec`, `project_spec`,
  `detect_spec`, `config_spec`) and layer-2 in-process `wizard_spec`, all runnable
  headless via `PlenaryBustedDirectory`.
- Add layer-3 golden-file equivalence (`golden_spec` + committed
  `fixtures/golden/`): plugin frontmatter output must be **byte-identical** to real
  `beans update` output across a scenario matrix, modulo `updated_at`.
- Add layer-4 end-to-end `e2e_spec` driving a real child Neovim over RPC with
  `nvim_input`, closing the loop through `beans show --json`, plus the negative case.
- Add CI (GitHub Actions on `nix develop`): `stylua --check` + layers 1-4 across the
  nixvim-pinned Neovim plus stable and nightly, and a scheduled golden-regeneration
  job to catch upstream Beans format drift.
- Add `tests/MANUAL.md` (layer-5 smoke checklist), complete `README.md` and
  `doc/beans.txt`, and verify every §12 Definition-of-Done item.
- Enforce a grep-as-test that no blocking prompt (`vim.fn.input`, `getchar`,
  `confirm`, `vim.ui.select/input`) exists anywhere in the wizard path.

## Capabilities

### New Capabilities

- `unit-wizard-tests`: hermetic layer-1 unit specs and layer-2 in-process wizard
  specs, with the fake-beans stub and shared test helpers.
- `golden-equivalence`: layer-3 golden-file matrix asserting the plugin's
  frontmatter writes are byte-identical to `beans update`.
- `e2e-ci-release`: layer-4 child-nvim end-to-end tests, CI gating, the manual
  smoke checklist, docs, and Definition-of-Done sign-off.

### Modified Capabilities

<!-- None. This milestone adds test/release capabilities; it does not change the
     requirements of the data-layer, wizard, or config capabilities. -->

## Impact

- New `tests/` tree (harness, fixtures, helpers, specs) and `fixtures/golden/`.
- New `.github/workflows/` CI, `stylua.toml` usage in CI, `tests/MANUAL.md`.
- Completed `README.md` and `doc/beans.txt`.
- No runtime code changes; `plenary.nvim` remains a test-only dependency. A real
  `beans` binary is required only for layer 3/4 regeneration; committed goldens let
  the matrix run without it.
- Depends on all prior milestones (01-04) being implemented; this milestone tests
  and signs off the whole PoC.
