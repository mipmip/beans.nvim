---
# beans.nvim-qmll
title: Repo scaffolding, module skeleton & tooling
status: todo
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:13:12Z
parent: beans.nvim-j5je
blocked_by:
    - beans.nvim-85rb
---

## Scope
- Create the lua/beans/ module tree of §9 as stubs (init, config, health, project,
  detect, cli, schema, frontmatter, completion, actions, wizard/*, steps/*).
- plugin/ entry that calls setup guard; after/ if needed for reload helper.
- stylua.toml; .gitignore excluding .dev/; README.md skeleton; doc/beans.txt stub.
- tests/ skeleton dirs (fixtures, helpers, *_spec.lua placeholders, minimal_init.lua).

## Acceptance
- [ ] `stylua --check` passes on the skeleton.
- [ ] Requiring `beans` and calling `setup()` does not error (even without `beans` bin).
- [ ] `.dev/` is gitignored.

Briefing §9.
