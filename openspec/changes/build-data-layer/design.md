## Context

Beans stores issues as markdown files with YAML frontmatter under a `.beans/`
directory. The Beans TUI spawns `$EDITOR` on the **real** bean file and blocks until the
editor exits. beans.nvim therefore operates on a live file that another process is
waiting for. The data layer must recognise such files, read supporting data from the
`beans` CLI, and edit the frontmatter — all without stalling Neovim's event loop and
without producing output Beans cannot round-trip.

Ground truth (verified against upstream `github.com/hmans/beans`):
- Frontmatter begins on line 1 with `---` and ends at the next `---`. The bean ID is a
  comment (`# beans-0ajg`) on the first line **inside** the frontmatter, not a YAML key.
- Canonical field order emitted by Beans:
  `title, status, type, priority, tags, created_at, updated_at, order, parent, blocking, blocked_by`.
  `title` and `status` are always present; the rest are `omitempty`.
- Vocabularies (`status`, `type`, `priority`) are hardcoded upstream and printed into
  `beans update --help`.

## Goals / Non-Goals

**Goals:**
- Attach plugin state to real bean buffers only; leave all other markdown untouched.
- Make every CLI read asynchronous and cached; never block the UI.
- Produce frontmatter edits byte-identical to what `beans update` would write.
- Keep `frontmatter.lua` a pure function of a line list so it is unit-testable without a
  live buffer or a running editor.

**Non-Goals:**
- The wizard UI, its steps, and interaction modes (Milestone 03).
- Insert-mode completion, user commands, and the full config surface (Milestone 04).
- The golden-file equivalence matrix and e2e tests (Milestone 05); this milestone only
  ships the layer-1 unit specs that gate the modules it introduces.

## Decisions

- **Writes edit the buffer, never the CLI.** During editing, all mutations are direct
  buffer edits; the plugin never shells out to `beans update` on an open bean. Rationale:
  the TUI holds the real file open and blocked, per-field subprocess latency would wreck
  the "single keystroke" feel, buffer edits give native undo for free, and nothing
  touches disk until `:w` — the contract the TUI expects. The CLI stays the source of
  truth for *reads* only.
- **Canonical field order is non-negotiable and not configurable.** Inserting a missing
  key places it at the position dictated by the order above, relative to keys already
  present. This is Beans' order, not ours; making it configurable would let a user
  produce files Beans does not round-trip cleanly.
- **Reads are async-only; never `:wait()` on the main loop.** `cli.lua` wraps
  `vim.system` with a callback API and JSON decode. Prefetch fires on `BufReadPost`:
  `beans update --help` (cached per project root for the session) and `beans list --json`
  (cached per root with a ~30s TTL, invalidated on `BufWritePost` of any bean). A step
  reached before its data arrives renders a loading state that self-replaces.
- **Vocabularies are discovered, with a fallback.** Parse `beans update --help`: match
  the line for `--<field>`, capture the first parenthesised group, split on commas, trim,
  and discard any item containing whitespace (this cleanly drops `or empty to clear`).
  If parsing yields nothing or the binary is missing, fall back to the static table in
  config. Never hardcode the mnemonic mapping — derive it from the discovered vocab
  (first letter → next unused letter in the word → digits `1..9`).
- **Detection is two independent OR'd checks.** (1) Path: walk up for `.beans.yml`
  (fallback: a `.beans/` directory), read `beans.path`, confirm the file lives under the
  resulting directory including `archive/`. (2) Content: the first `max_lines` lines
  contain `---`, a `# <id>` comment, and a `title:` key. Either is sufficient.
- **Do not set a compound filetype** like `markdown.beans`. Many plugins compare
  `filetype` with `==`, which would sporadically break LSP/treesitter attachment. State
  lives in the invisible buffer variable `vim.b.beans = { id, root, beans_dir, bufnr }`.
- **Auto-start is a heuristic, not process detection.** The wizard auto-start condition
  (owned here as detection metadata) requires ALL of: a recognised bean, `created_at`
  within `autostart.max_age_seconds` of now, and an empty/whitespace-only body.

## Risks / Trade-offs

- **Upstream format drift.** If Beans changes its canonical order, quoting, or list
  indentation, the frontmatter engine diverges. Mitigation: discover vocab at runtime,
  keep the engine narrow, and gate it with the layer-3 golden matrix in Milestone 05.
- **`tags:` block indentation is version-sensitive** (`yaml.v3` defaults to 4 spaces but
  must be verified). Mitigation: when a `tags:` block already exists, match its existing
  indentation rather than assuming; otherwise use the verified emitted indent.
- **`updated_at` is not bumped by buffer edits.** Acceptable for v1 (the bean was just
  created); `write.touch_updated_at` remains available if the `beans serve` watcher is
  later confirmed not to refresh it.
- **Async prefetch races the wizard.** A fast user could reach the tags/parent step
  before `beans list --json` returns; the loading state absorbs this rather than blocking.
- **Content-check false positives.** A hand-written markdown file mimicking bean
  frontmatter would be detected. Accepted: the content check is the deliberate safety net
  for worktree/temp-file cases, and the consequence is limited to buffer-local keymaps.
