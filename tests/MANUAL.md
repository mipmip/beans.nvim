# Manual smoke checklist (layer 5)

The Bubbletea TUI is not worth automating; this is the short list to run by hand
in the flake's scratch project (`.dev/scratch/`, created by `nix develop`) before
each release. Everything else is covered by layers 1–4 in CI.

Run `nix develop`, then `cd .dev/scratch` (or any `beans init` project).

- [ ] From `beans tui`, create a bean; nvim opens with the wizard already up.
- [ ] Complete all five steps by keyboard only — no mouse, no command line:
  - [ ] `status` / `type` / `priority` each set with a single letter, auto-advancing.
  - [ ] `tags`: `j`/`k` to move, `<Space>` to toggle, `n` to add a new tag
        (invalid tags are rejected with a message), `<CR>`/`<Tab>` to confirm.
  - [ ] `parent`: type to filter, `<C-n>`/`<C-p>` to move, `<CR>` to select.
- [ ] `:wq`; the TUI shows the bean with the chosen values.
- [ ] Repeat, pressing `<Esc>` immediately: the bean keeps its defaults and is
      still a valid bean.
- [ ] After finishing, `u` walks back through the picks one at a time; five undos
      restore the file to its as-opened state.
- [ ] Repeat inside a git worktree whose bean directory is the worktree's own
      `.beans/` — detection still fires.
- [ ] With `beans serve` running, confirm the web UI reflects the saved values.
- [ ] Open an **old** bean (created_at well in the past): the wizard does **not**
      auto-start. `<leader>bw` starts it manually.
- [ ] Open a plain markdown file outside any beans project: no float, no keymaps,
      no popups. `:checkhealth beans` explains why it is not recognised.
