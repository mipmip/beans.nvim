# beans.nvim — Autonomous Build Playbook

This repository is a **planned but not-yet-implemented** PoC for `beans.nvim`, a
Neovim plugin for the [Beans](https://github.com/hmans/beans) flat-file issue
tracker. Everything needed to build it autonomously is already in place:

- **The full design spec:** [`docs/dev/beans-nvim-briefing.md`](docs/dev/beans-nvim-briefing.md).
  This is ground truth for *what* to build. Read it before writing any code.
- **The roadmap:** tracked as **beans** in `.beans/` — 5 milestones (`01`–`05`),
  each with child epics, sequenced with a `blocked-by` chain.
- **The work packages:** tracked as **OpenSpec changes** in `openspec/changes/` —
  one change per milestone, each carrying `proposal.md`, `design.md`, per-capability
  `specs/`, and a `tasks.md` grouped by epic.

Your job as the build agent is to walk the roadmap milestone by milestone, turning
each OpenSpec change's tasks into working, tested code.

---

## The tools

| Concern | Tool | Notes |
| --------------------- | ---------- | ------------------------------------------------- |
| Milestones & epics    | `beans`    | Run `beans prime` once to load the full agent guide. |
| Proposals & tasks     | `openspec` | One change per milestone. `openspec list`, `openspec view`. |
| Version control       | `jj`       | Colocated with git. Remote `origin` already set.  |
| Build & test env      | `nix`      | `nix develop` (built in Milestone 01).            |

Identity for all commits: **Pim Snel <post@pimsnel.com>**. No self-promotion, no
"Co-Authored-By", no tool advertising in commit messages.

---

## The build loop

Work **one milestone at a time, in numeric order** (`01` → `05`). For each:

1. **Pick the work.** `beans list --json --ready` surfaces exactly the next epic
   (the chain enforces order). `beans show --json <id>` for detail. Mark the
   milestone and the epic you start `in-progress`:
   `beans update <id> -s in-progress`.

2. **Load the plan.** The milestone maps to an OpenSpec change (the mapping is in
   the milestone bean body). Read it:
   `openspec show <change> --json --deltas-only` and open its `tasks.md`,
   `design.md`, and `specs/`.

3. **Implement + test.** Work the tasks in `tasks.md` top to bottom, checking
   each off (`- [ ]` → `- [x]`) as you finish it. Keep the corresponding **beans
   epic** body's checklist current in lockstep. Follow the briefing's testing
   layers (§11) — **thorough tests and e2e are a requirement, not optional**:
   - Layers 1–2 (unit + in-process wizard) for every module you touch.
   - Layer 3 (golden-file equivalence vs real `beans update`) is the acceptance
     test that proves the buffer-editing decision is safe.
   - Layer 4 (child-nvim e2e) closes the loop through the real CLI.
   Run the suite headless before considering an epic done.

4. **Close the epic.** When every task in an epic is checked and its tests pass,
   add a `## Summary of Changes` section to the epic bean and mark it
   `completed`. Move to the next ready epic.

5. **Finish the change.** When all of a milestone's epics are completed and
   `openspec validate <change> --strict` passes:
   - **Archive it:** `/opsx:archive <change>` (or `openspec archive <change>`).
     This syncs delta specs into `openspec/specs/` and moves the change to
     `openspec/changes/archive/`.
   - **Commit immediately** (see next section). Then mark the **milestone** bean
     `completed` with a summary.

Repeat until Milestone 05 is done and every §12 Definition-of-Done box is checked.

---

## Commit discipline (jj)

**Commit after every archival of an OpenSpec change** — that is the commit
cadence for this project. A commit bundles the code, the tests, the updated bean
files, and the archived OpenSpec change together.

```bash
# after archiving a change:
jj commit -m "milestone 0X: <change-name> — <short summary>"
jj bookmark set main -r @-      # move the main bookmark to the new commit
jj git push                      # push to origin
```

- Commit as **Pim Snel <post@pimsnel.com>** (already the configured jj identity).
- One archival = one commit = one push. Keep messages factual; describe what was
  built, not who built it. **No self-promotion of any kind.**
- Include the bean files and the archived `openspec/changes/archive/...` in the
  same commit as the code.

Smaller intermediate commits within a milestone are fine, but the archival commit
is the mandatory checkpoint.

---

## Hard rules (from the spec — do not violate)

- **Buffer edits, not CLI, during the wizard.** Never shell out to `beans update`
  while a bean file is open in the editor (briefing §5).
- **No blocking prompts anywhere in the wizard path** — no `vim.fn.input`,
  `getchar`, `confirm`, or `vim.ui.select` inside the wizard. This is enforced by
  a grep-based test (§11.0).
- **Canonical frontmatter field order is Beans', not ours** and is not
  configurable (§2.2).
- **Vocabularies are discovered at runtime** from `beans update --help`, never
  hardcoded (§2.3); the config table is only a fallback.
- **Non-bean markdown gets zero footprint** — no keymaps, autocmds, commands with
  effects, or popups (§6).
- **Nix from the start, plain nix for systems** — no `flake-utils`; iterate a
  `systems` list for supported architectures (§10).
- The acceptance test that matters most is the **golden-file byte-equivalence**
  against the real `beans` CLI (§11.3, §12).

---

## Quick reference

```bash
beans prime                       # (re)load the beans agent guide
beans list --json --ready         # the next epic to work
beans show --json <id> [id...]    # detail
openspec list                     # active changes
openspec show <change> --json     # a change's artifacts
openspec validate <change> --strict
openspec archive <change>         # after all its epics are completed
nix develop                       # isolated dev nvim + beans (from Milestone 01)
```
