## Context

beans.nvim edits the frontmatter of a markdown file that the Beans Bubbletea TUI
opened via `$EDITOR` and is blocking on. The core architectural bet (briefing §5) is
that all wizard mutations are **direct buffer edits** — the plugin never shells out to
`beans update` while the file is open. That bet is only defensible with a test that
diffs plugin output against the real CLI. This milestone builds the whole test
pyramid and the release scaffolding; it changes no runtime behaviour.

The test design is itself a constraint on the runtime code: because tests must drive
the wizard with `nvim_feedkeys`/`nvim_input`, the wizard may never call a blocking
prompt. That constraint (briefing §11.0) was baked into earlier milestones; here we
assert it with a grep-as-test.

## Goals / Non-Goals

**Goals:**

- Prove buffer-editing is safe: byte-identical equivalence with `beans update` across
  a full scenario matrix (the acceptance test that matters most, briefing §12).
- Fast, hermetic layers 1-2 that need no real `beans` binary (fake-beans stub).
- A real end-to-end run (layer 4) through a separate child Neovim that catches what
  in-process tests structurally cannot: unattached keymaps, floats that never open,
  autocmds firing twice, mappings leaking into the parent buffer, finish-mode bugs.
- CI that gates every merge and a scheduled job that regenerates goldens to detect
  upstream Beans schema drift early.
- Complete docs (README, vimdoc, manual checklist) and a verified §12 DoD.

**Non-Goals:**

- Automating the Bubbletea TUI itself (briefing §11.5) — that is the one thing left
  to a short manual checklist (layer 5).
- Testing deferred v1 non-goals (briefing §13): bean browser, statusline, live
  `beans serve` integration, etag concurrency.
- Changing any spec-level behaviour of the data layer, wizard, or config.

## Decisions

- **Five layers, 1-4 automated + 5 manual.** Layer 1 = hermetic unit specs. Layer 2 =
  in-process wizard specs against a real buffer. Layer 3 = golden-file equivalence.
  Layer 4 = e2e through a child Neovim. Layer 5 = a manual smoke checklist for the TUI
  loop. Layers 1-4 gate CI.
- **Hermetic by default via a fake-beans stub.** An executable `tests/fixtures/fake-beans`
  on `PATH` emits canned `--help` text and canned JSON so layers 1-2 run with no real
  binary and no network. `helpers/project.lua` builds a temp Beans project on disk;
  `helpers/child.lua` spawns and drives a child nvim over RPC.
- **Golden-file matrix is the safety proof.** For each scenario (set status/type/
  priority; clear priority; add one tag; add three tags; remove a tag; remove all
  tags; set parent; clear parent; set a title containing a colon), against both a
  fully-populated and a minimal bean: create a bean, copy to `A.md`/`B.md`, apply the
  change to A via `beans update` and to B via the plugin's `frontmatter.lua`, and
  assert the files are **byte-identical apart from `updated_at`**. CLI outputs are
  committed as golden files so the matrix runs without a `beans` binary; a scheduled
  CI job regenerates them against the latest Beans release so a schema change trips an
  early alarm rather than a silent production break.
- **Layer 4 uses real keystrokes, not feedkeys.** The e2e spec spawns a real,
  separate Neovim (`--embed --headless`) over RPC and drives it with `nvim_input`
  (terminal-style input), then asserts on what the child reports. The canonical
  scenario is the product in briefing §1: write a TUI-style bean (title +
  `created_at` = now + defaults + empty body), open it, assert the wizard float
  exists, send `i` `b` `h`, send `<Tab>` `<Tab>` to skip tags/parent, assert mode is
  `i` with the cursor on the last body line and no float, then `:w` and assert
  `beans show <id> --json` reports the three chosen values — closing the loop through
  the real CLI. A second, equally important scenario opens a plain markdown file
  **outside** any Beans project and asserts no float, `vim.b.beans == nil`, and that
  `<leader>bw` does nothing.
- **Testability is enforced, not assumed.** A grep-as-test fails if `vim.fn.input`,
  `vim.fn.getchar`, `vim.fn.confirm`, or `vim.ui.select`/`vim.ui.input` appear
  anywhere in the wizard path. These are still permitted in the random-access
  `:Bean <field>` path outside the wizard, where `vim.ui.select` can be stubbed.
- **CI matrix.** GitHub Actions runs inside `nix develop`: `stylua --check`, then
  layers 1-4 headless, against the nixvim-pinned Neovim plus stable and nightly,
  since floating-window and `vim.system` behaviour are the parts most likely to
  drift. The golden-regeneration job runs on a schedule.
- **DoD is a task group.** The §12 Definition-of-Done checklist is enumerated as
  tasks so the change cannot be archived with a box unchecked.

## Risks / Trade-offs

- **Golden drift.** If Beans changes its frontmatter serialisation, committed goldens
  go stale. Mitigation: the scheduled regen job diffs fresh CLI output against the
  committed goldens and fails loudly — the intended early-warning signal.
- **`tags:` block indentation is version-sensitive.** `yaml.v3` defaults to 4 spaces
  but this must be verified against the installed Beans (briefing §14.1). Layer 3 will
  surface any mismatch immediately as a non-identical diff; the frontmatter engine
  matches existing block indentation when present.
- **Child-nvim flakiness.** RPC/timing races in layer 4 can cause intermittent
  failures. Mitigation: poll on observable child state (window list, mode, buffer
  lines) with bounded waits rather than fixed sleeps; keep the scenario minimal.
- **Nightly Neovim breakage.** Running against nightly can fail for reasons outside
  the plugin. Trade-off accepted: nightly is a signal, and floating-window/`vim.system`
  regressions are exactly what we want to catch early; pin the nixvim Neovim as the
  authoritative gate.
- **`updated_at` handling.** The plugin does not bump `updated_at`; the golden
  comparison must normalise that single field. If §14.2 shows the `beans serve`
  watcher does not refresh it, the write-config flag exists to set it — but the
  equivalence test deliberately ignores it to stay robust to either choice.
