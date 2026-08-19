## 1. Selection indicator (beans.nvim-7wcj)

- [ ] 1.1 `ui.render`: add a left-gutter caret glyph (e.g. `▸`) for the current option,
  distinct from the `●` active marker; keep the mnemonic/active/label highlight column
  math correct after the added gutter.
- [ ] 1.2 Default `BeansWizardCurrent` to link `PmenuSel` (was `CursorLine`); still
  overridable.
- [ ] 1.3 Applies to all cards (enum, tags, parent); existing wizard specs stay green.
- [ ] 1.4 Spec/tests: a card with a highlighted option shows the caret indicator.

## 2. Parent title comment (beans.nvim-y3rv)

- [ ] 2.1 `frontmatter.set_scalar`: optional `comment` arg appended after the serialized
  value (never folded into the value); replacing a commented value strips the old comment
  (no stacking); no comment ⇒ output unchanged.
- [ ] 2.2 `config.lua`: add `fields.parent.title_comment = true`.
- [ ] 2.3 `wizard/steps/parent.lua`: on select, pass the candidate's title as the comment
  when `fields.parent.title_comment` is enabled.
- [ ] 2.4 Confirm the reading side is unaffected (parent is not parsed by detection or the
  enum current-value logic); only the engine replace-path handles an existing comment.
- [ ] 2.5 Update the §12 DoD note: byte-identical for Beans-owned fields; the plugin may
  add a trailing title comment on `parent`.

## 3. Tests & docs

- [ ] 3.1 `frontmatter_spec.lua`: comment appended; no-stack on replace; no-comment
  byte-identical; golden matrix still passes (it passes no comment).
- [ ] 3.2 `wizard_spec.lua`: selecting a parent writes `parent: <id> # <title>`;
  `title_comment = false` writes the bare id.
- [ ] 3.3 `config_spec.lua`: default `fields.parent.title_comment == true`.
- [ ] 3.4 `nix develop` full suite green (`scripts/test.sh tests/`), stylua clean.

## 4. Verification

- [ ] 4.1 Manually confirm in `nix develop`: the selected option is obvious, and setting a
  parent shows `parent: <id> # <title>`.
