## Why

beans.nvim must be buildable, testable, and hackable from the very first commit,
without touching the developer's real Neovim config and without anyone hand-installing
tools. The briefing (§10) mandates a Nix flake that yields an isolated NixVim instance
with `beans` on `PATH`, and (§9) a fixed module layout that every later milestone fills
in. Getting this foundation right — reproducible, self-contained, plain-nix — is the
precondition for all subsequent work; nothing else can "take off" until `nix develop`
and the repo skeleton exist.

## What Changes

- A `flake.nix` (+ committed `flake.lock`) that builds an isolated NixVim editor and a
  `devShells.default`, using **plain nix** to enumerate supported systems (no
  `flake-utils`).
- The `beans` binary is made available inside the dev shell so the real TUI →
  `$EDITOR` → nvim loop can be exercised.
- Reload/test helpers (`_G.reload_beans()` on `<leader>rr`, test runner on `<leader>rt`).
- The complete `lua/beans/` module tree (§9) created as loadable stubs, plus `plugin/`
  entry, `stylua.toml`, `.gitignore` (excludes `.dev/`), `README.md` skeleton,
  `doc/beans.txt` stub, and the `tests/` skeleton.
- A scratch fixture project at `.dev/scratch/` with `beans init` already run.

## Capabilities

### New Capabilities

- `dev-environment`: A plain-nix flake providing an isolated NixVim editor and dev shell
  with `beans`, reload/test helpers, and per-project XDG isolation.
- `project-scaffolding`: The canonical repository skeleton — module tree, tooling
  config, docs stubs, and test harness layout — that later milestones populate.

### Modified Capabilities

<!-- None: this is the first change; there are no existing capabilities to modify. -->

## Impact

- New files: `flake.nix`, `flake.lock`, `.gitignore`, `stylua.toml`, `README.md`,
  `doc/beans.txt`, the `lua/beans/**` tree, `plugin/beans.lua`, `tests/**` skeleton.
- New (git-ignored) directory: `.dev/` with an isolated XDG tree and `scratch/`.
- Toolchain dependencies pinned via Nix: `nixpkgs` (nixos-unstable), `nixvim`,
  `plenary.nvim`, `nvim-treesitter`, `lua-language-server`, `stylua`, and `beans`
  (available in nixpkgs as `pkgs.beans`, currently v0.4.2).
- No runtime dependencies added to the plugin itself; `plenary.nvim` is test-only.
