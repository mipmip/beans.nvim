## 1. configuration (beans.nvim-62q6)

- [x] 1.1 Create `lua/beans/config.lua` with the complete default table from briefing
      §7.3 (executable, timeout, detect, wizard, fields, write, completion, keymaps,
      hooks, notify, fallback), verbatim in structure and default values.
- [x] 1.2 Implement `M.setup(user)` merging via `vim.tbl_deep_extend("force",
      defaults, user or {})`; ensure list-valued leaves (e.g. `wizard.keys.finish`)
      replace rather than concatenate.
- [x] 1.3 Implement validation: type-check known keys; for each invalid value emit at
      most one `vim.notify` (respecting `notify` level / `false` to silence) naming
      the key and the fallback, then substitute the default; never error.
- [x] 1.4 Ensure `setup()` does not error when `beans` is absent from `$PATH` (defer
      to a `:checkhealth` warning); expose the resolved config to other modules.
- [x] 1.5 Wire `fallback` vocab table through to `schema.lua` for use when help
      parsing fails.
- [x] 1.6 `config_spec.lua` (§11.1): no-arg setup == full defaults; empty-table setup
      == full defaults; partial merge keeps siblings (keymap and nested wizard cases);
      invalid value warns once and falls back; `notify = false` suppresses; missing
      binary does not error.

## 2. commands-keymaps (beans.nvim-5ug8)

- [x] 2.1 Register user commands in `init.lua`: `:BeanWizard`, `:Bean` (field menu →
      value picker), `:Bean <field>` with `complete` returning field names, and the
      `:checkhealth beans` provider entry.
- [x] 2.2 Implement `health.lua` reporting: `beans` binary + version, project root,
      bean directory, whether the current buffer is recognised and why not if not,
      discovered vocabularies, and cache state (briefing §6).
- [x] 2.3 Implement `actions.lua` random-access entry points: use the buffer-edit
      code path when the target bean is open in a buffer; fall back to `beans update`
      only when the bean is not open. `vim.ui.select`/`vim.ui.input` may be used here
      (outside the wizard) and must be stubbable in tests.
- [x] 2.4 Attach buffer-local keymaps (§7.2: wizard, menu, status/type/priority,
      tags, parent) on bean detection via the `beans.nvim` augroup; honour
      `keymaps.enabled = false` and per-entry overrides / `false` to unbind.
- [x] 2.5 Fire `hooks.on_attach(ctx)` after detection and `hooks.on_finish(ctx,
      changed)` after the wizard closes, with `ctx = { id, root, beans_dir, bufnr }`.
- [x] 2.6 Verify commands and keymaps attach only in bean buffers and never in plain
      markdown (cross-checked by detect/e2e layers).

## 3. insert-completion (beans.nvim-vpcl)

- [x] 3.1 Create `completion.lua`; set buffer-local `omnifunc` in bean buffers only.
- [x] 3.2 Implement the context gate: complete only inside the frontmatter block after
      a known key — `status:`, `type:`, `priority:`, `parent:`, or a `tags:` list
      item; return nothing otherwise.
- [x] 3.3 Source completion values from `schema.lua` (vocab for enums; `beans list
      --json` tag/parent candidates for tags/parent).
- [x] 3.4 Add optional `blink.cmp` and `nvim-cmp` sources behind `completion.blink` /
      `completion.cmp` (default off), lazily `require`d; absent plugin causes no error.
- [x] 3.5 Add NO insert-mode `<Tab>`/`<CR>` mappings anywhere.
- [x] 3.6 Cover the context gate and optional-source no-op behaviour in specs.
