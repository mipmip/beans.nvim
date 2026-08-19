## Context

Investigated during an explore session. Two independent findings:

- The wizard render marks the cursor row only with `BeansWizardCurrent` (→ `CursorLine`),
  and `cursorline` is off on the float, so selection is often invisible. The `●` glyph is
  the *active* marker (value already on the bean), a different concept.
- `parent` is a scalar id with no human context. An inline YAML comment
  (`parent: id # title`) is valid — Beans reads the id and ignores the comment — but Beans
  drops the comment when it next rewrites the file (go-yaml discards inline comments), and
  `beans update --parent X` never writes one.

## Goals / Non-Goals

**Goals:**
- Make the selected option unmistakable on every card.
- Show the parent's title inline right after it is set, confirming the pick.

**Non-Goals:**
- Editing `blocking`/`blocked_by` or commenting their items (separate change,
  `beans.nvim-ipmb`).
- Keeping the comment alive across Beans rewrites (explicitly accepted as transient).

## Decisions

- **Selection indicator (all cards).** Add a caret glyph (`▸`) in a left gutter for the
  current option, kept visually distinct from the `●` active marker. Default
  `BeansWizardCurrent` to link `PmenuSel` (the popup-selection group every colorscheme
  styles) instead of `CursorLine`. Both remain overridable.

- **Comment is a write-time argument, not a data field.** `frontmatter.set_scalar` gains
  an optional `comment` parameter, appended AFTER the value is serialized/quoted. It must
  not be folded into the value string: the minimal-quoting rule quotes any value
  containing `#` or spaces, so `set_scalar(…, "parent", "id # title")` would wrongly emit
  `parent: 'id # title'`. Replacing a value that already carries a trailing ` # …` strips
  the old comment first (no stacking).

- **Byte-identity preserved.** Because the engine adds the comment only when a caller
  passes one, the layer-3 golden matrix (which never passes a comment) stays byte-identical
  to `beans update`. Only the live wizard write intentionally diverges by adding the
  comment; record this as a one-line amendment to the §12 DoD ("byte-identical for
  Beans-owned fields; the plugin may add a trailing title comment on `parent`").

- **Default on, configurable.** `fields.parent.title_comment = true`; set `false` for
  strict byte-identity on the parent line.

- **No re-add after Beans strips it.** Deliberately not implemented: re-writing the comment
  would fight Beans and, with `beans serve`'s watcher, cause a strip → re-add → strip loop.

## Risks / Trade-offs

- The indicator gutter shifts the highlight column math for the mnemonic/active/label
  spans in `ui.render`; covered by keeping the existing wizard specs green.
- Reading side is narrow: `parent` is not parsed by detection or the enum "current value"
  logic, so a trailing comment cannot leak into those. The only case to handle is the
  engine replacing an already-commented `parent` value (the no-stack rule above).
