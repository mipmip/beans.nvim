---
# beans.nvim-y3rv
title: Parent value carries the parent title as a trailing comment
status: completed
type: feature
priority: normal
created_at: 2026-08-19T20:31:20Z
updated_at: 2026-08-19T20:39:13Z
parent: beans.nvim-ad08
---

When the plugin sets `parent`, append the parent's title as a YAML inline comment,
e.g. `parent: beans.nvim-slzt # 03 The Wizard`, so the user immediately sees the
parent is correct right after editing. Beans strips the comment on its next rewrite;
that is acceptable — we do NOT re-add it (avoids a beans-serve strip/re-add churn loop).

## Design (decided in explore)
- The comment is a WRITE-TIME argument, not a data field: `frontmatter.set_scalar`
  gains an optional `comment` param appended AFTER the value is serialized/quoted (the
  comment must NOT be folded into the value, or minimal-quoting would quote the whole
  thing). Replacing an existing commented parent strips the old ` # ...` (no stacking).
- Byte-identity contract is preserved: the engine adds the comment ONLY when asked, so
  the layer-3 golden test (which does not pass a comment) stays byte-identical to
  `beans update`. Only the live wizard write intentionally diverges — record this in
  the §12 DoD note.
- Config: `fields.parent.title_comment = true` (default on, overridable).

## Acceptance
- [ ] Selecting a parent writes `parent: <id> # <title>` when title_comment is on.
- [ ] Re-picking replaces (no stacked comments); title_comment=false writes bare id.
- [ ] Golden matrix still byte-identical; §12 DoD note updated.

## Summary of Changes
frontmatter.set_scalar gained an optional comment arg (appended after the quoted value,
no stacking on replace, byte-identical when omitted). Parent step passes the candidate
title when fields.parent.title_comment (default true). Verified: parent: <id> # <title>.
§12 DoD note updated; golden matrix unaffected.
