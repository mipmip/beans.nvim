---
# beans.nvim-w3rq
title: CLI & schema layer (async reads, vocab, prefetch, cache)
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:12Z
parent: beans.nvim-diz4
blocked_by:
    - beans.nvim-za8d
---

## Scope (cli.lua, schema.lua)
- Async `vim.system` wrapper + JSON decode; never `:wait()` on the main loop; cwd=root;
  honour `--beans-path`.
- Vocab discovery by parsing `beans update --help` (§2.3 rule: match `--<field>`, first
  paren group, split commas, drop whitespace items). Fallback to config table.
- Dynamic mnemonic assignment (first letter -> next free letter -> digits 1..9).
- Prefetch on BufReadPost: `beans update --help` (per-root session cache) and
  `beans list --json` (per-root, ~30s TTL, invalidate on BufWritePost of any bean).
- Static hint table from config.go descriptions (lookup miss is fine).

## Acceptance
- [ ] Help parsing incl. the `or empty to clear` tail; fallback when missing/unparsable.
- [ ] Mnemonics incl. forced-collision vocab falling through to digits.
- [ ] Loading state shown when a step is reached before data lands.

Briefing §2.3, §5.3, §11.1(2), verify §14.4/§14.5.
