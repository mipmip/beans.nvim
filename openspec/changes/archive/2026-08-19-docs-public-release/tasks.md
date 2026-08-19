## 1. Expand doc/beans.txt into the full reference

- [x] 1.1 Update the CONTENTS block with new sections and `*beans-*` tags: Highlight groups (`beans-highlights`), Completion (`beans-completion`), Detection & troubleshooting (`beans-detection`), Non-goals (`beans-non-goals`).
- [x] 1.2 Replace the Configuration section's briefing pointer with the complete config reference, transcribing every default from `lua/beans/config.lua` `M.defaults` (executable, timeout, detect, wizard incl. keys/window/flash/finish, fields incl. `parent.title_comment = true`, write, completion, keymaps, hooks, notify, fallback).
- [x] 1.3 Add the Highlight groups section (`*beans-highlights*`): list each `Beans*` group and the standard group it links to (BeansWizardTitle→Title, BeansWizardKey→Special, BeansWizardCurrent→PmenuSel, BeansWizardActive→DiagnosticOk, BeansWizardHint→Comment, BeansFieldLine→Visual, BeansFlash→IncSearch) — verified against `lua/beans/wizard/ui.lua` (note: code uses PmenuSel, not the briefing's CursorLine).
- [x] 1.4 Add the Completion section (`*beans-completion*`): omnifunc default-on in bean buffers, optional blink.cmp / nvim-cmp behind `completion.blink` / `completion.cmp`, no insert-mode `<Tab>`/`<CR>` mappings.
- [x] 1.5 Add the Detection & troubleshooting section (`*beans-detection*`): the two OR'd checks (by_path, by_content), auto-start conditions (recognised bean, `created_at` within `max_age_seconds`, empty body), and fold the existing Health content in as the self-diagnosis path.
- [x] 1.6 Add the Non-goals section (`*beans-non-goals*`) summarising §13 (no bean browser, no create-from-nvim, no statusline, no serve integration, etc.).
- [x] 1.7 Document `hooks.on_attach(ctx)` and `hooks.on_finish(ctx, changed)` with their argument shapes (ctx = { id, root, beans_dir, bufnr }).
- [x] 1.8 Remove every `beans-nvim-briefing.md` reference from `doc/beans.txt`.

## 2. Trim README.md to a self-sufficient quickstart

- [x] 2.1 Replace the "The complete default table lives in beans-nvim-briefing.md §7.3" pointer with a link to `:help beans-config`.
- [x] 2.2 Verify the README's config snippet and any stated defaults match `lua/beans/config.lua`; correct any drift (snippet already matched — no drift).
- [x] 2.3 Ensure no `beans-nvim-briefing.md` reference remains in `README.md`; where a deeper reference is useful, point at the relevant `:help beans-*` tag.

## 3. Relocate the briefing

- [x] 3.1 `jj`/git-move `beans-nvim-briefing.md` to `docs/dev/beans-nvim-briefing.md` (preserving history).
- [x] 3.2 Update the path reference(s) in `CLAUDE.md` to `docs/dev/beans-nvim-briefing.md`.
- [x] 3.3 Update path references in code/test comments (`lua/beans/config.lua`, `lua/beans/frontmatter.lua`, `lua/beans/init.lua`, `tests/frontmatter_spec.lua`) to the new path; leave bare "§N" citations unchanged.
- [x] 3.4 Leave `.beans/*.md` historical bean bodies untouched (archival records).

## 4. Verify

- [x] 4.1 Regenerate help tags: `nvim --headless -c 'helptags doc/' -c 'q'` and confirm `doc/tags` includes the new `beans-*` tags.
- [x] 4.2 Confirm every `:help beans-*` link used in README resolves to a `*beans-*` tag defined in `doc/beans.txt`.
- [x] 4.3 Grep the repo (excluding `docs/dev/beans-nvim-briefing.md`, `.beans/`, and `openspec/changes/archive/`) for `beans-nvim-briefing` and confirm only intended references remain.
- [x] 4.4 Diff every documented default against `lua/beans/config.lua` and confirm they match.
- [x] 4.5 Run the headless test suite and confirm layers 1–4 still pass (no behaviour changed).
- [x] 4.6 `openspec validate docs-public-release --strict` passes.
