## 1. bean-detection (beans.nvim-za8d)

- [ ] 1.1 Implement `lua/beans/project.lua`: walk upward for `.beans.yml` (fallback
  `.beans/`), hand-rolled reader for `beans.path` (no YAML dependency), resolve project
  root and bean directory.
- [ ] 1.2 Implement `lua/beans/detect.lua`: path check (file under bean dir incl.
  `archive/`) and content check (first `detect.max_lines` lines contain `---`, `# <id>`,
  `title:`), OR'd together.
- [ ] 1.3 On positive detection set `vim.b.beans = { id, root, beans_dir, bufnr }` and
  attach buffer-local keymaps via the `beans.nvim` augroup; never set a compound filetype.
- [ ] 1.4 Guarantee zero footprint on non-bean markdown (no keymaps/commands/autocmds/
  popups when unmatched).
- [ ] 1.5 Implement the auto-start heuristic (recognised bean AND `created_at` within
  `autostart.max_age_seconds` AND empty/whitespace body when `require_empty_body`).
- [ ] 1.6 Add basic `:checkhealth beans` reporting (binary+version, root, bean dir,
  buffer recognised?/why-not) in `lua/beans/health.lua`.
- [ ] 1.7 `tests/project_spec.lua`: root from nested dirs, custom `beans.path`, no-project
  case.
- [ ] 1.8 `tests/detect_spec.lua`: detected by path, by archive path, by content; and the
  negative — plain markdown outside a project attaches nothing (`vim.b.beans == nil`, no
  plugin keymap).
- [ ] 1.9 `tests/detect_spec.lua` (auto-start): fires on a fresh empty bean; does not fire
  on an old bean, a bean with a body, or when disabled.

## 2. cli-schema (beans.nvim-w3rq)

- [ ] 2.1 Implement `lua/beans/cli.lua`: async `vim.system` wrapper with callback API and
  JSON decode; `cwd` = project root; honour `--beans-path`; never `:wait()` on the main
  loop.
- [ ] 2.2 Implement `lua/beans/schema.lua` vocabulary discovery from `beans update --help`
  (match `--<field>`, first paren group, split on commas, trim, drop whitespace items);
  fall back to config vocab on failure/missing binary.
- [ ] 2.3 Implement dynamic mnemonic assignment (first letter → next unused letter →
  digits `1..9`), guaranteeing uniqueness.
- [ ] 2.4 Implement prefetch on `BufReadPost` (`beans update --help`, `beans list --json`)
  with per-root vocab cache (session) and per-root list cache (~30s TTL, invalidated on
  `BufWritePost` of any bean); expose a loading state.
- [ ] 2.5 Add the static hint table (value descriptions from Beans' `config.go`); a lookup
  miss is acceptable.
- [ ] 2.6 Build `tests/fixtures/fake-beans` executable stub emitting canned `--help` text
  and canned JSON; ensure it is on `PATH` for the suite.
- [ ] 2.7 `tests/schema_spec.lua`: help parsing incl. the `or empty to clear` tail;
  fallback when parsing fails or the binary is missing; mnemonic assignment incl. a
  forced-collision vocabulary that must fall through to digits.

## 3. frontmatter-engine (beans.nvim-888o)

- [ ] 3.1 Implement `lua/beans/frontmatter.lua` as a pure line-list module: locate `---`…
  `---`; bail if line 1 is not exactly `---`.
- [ ] 3.2 Scalar set: replace value on `^(\s*)<key>:\s*(.*)$`, preserve indentation,
  minimal quoting (`:`, `#`, leading/trailing space, YAML-ambiguous words), incl. titles
  with colons.
- [ ] 3.3 Scalar insert at the canonical position
  (`title, status, type, priority, tags, created_at, updated_at, order, parent, blocking,
  blocked_by`), relative to present keys.
- [ ] 3.4 Scalar clear (priority): remove the line rather than writing an empty value.
- [ ] 3.5 List set/clear (tags) as a block sequence; match an existing `tags:` block's
  indentation, else use Beans' emitted indent; clear removes key and all items.
- [ ] 3.6 Preserve the `# <id>` comment and never touch `created_at`/`updated_at`/`order`;
  apply each field via a single `nvim_buf_set_lines` call (one undo step).
- [ ] 3.7 `tests/frontmatter_spec.lua`: replace existing scalar; insert missing scalar at
  each gap (type-missing, priority-missing, parent-missing, tags-missing, title+status
  only); clear a scalar; write and clear a tag list; preserve `# id`/created_at/
  updated_at/order; titles with colons/quotes/`#`/leading-trailing space; byte-identical
  no-op when setting a value to what it already was.
