## ADDED Requirements

### Requirement: Isolated NixVim development shell

The flake SHALL provide a `devShells.default` that launches an isolated NixVim editor
whose configuration and state never touch the developer's real Neovim config. The shell
SHALL redirect `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and
`XDG_CACHE_HOME` under `$(pwd)/.dev/`, create those directories, export
`BEANS_NVIM_DEV_PATH="$(pwd)"`, and print a short help banner.

#### Scenario: Entering the dev shell isolates config

- **WHEN** a developer runs `nix develop` in the repository root
- **THEN** the shell exports `BEANS_NVIM_DEV_PATH` and points every `XDG_*_HOME`
  variable inside `$(pwd)/.dev/`, leaving `~/.config/nvim` untouched

#### Scenario: Editor loads the working-tree plugin

- **WHEN** nvim is launched from the dev shell (`nix run` or via the shell)
- **THEN** the plugin source at `BEANS_NVIM_DEV_PATH` (falling back to the flake's own
  path) is prepended to `runtimepath` and `require("beans")` resolves to the working tree

### Requirement: `beans` CLI available in the environment

The dev shell and the built editor SHALL make the `beans` binary available on `PATH`
without any additional installation. The binary SHALL be sourced from nixpkgs
(`pkgs.beans`, `github.com/hmans/beans`); a `buildGoModule` derivation pinned to a
release tag SHALL be used only if nixpkgs cannot supply a required version.

#### Scenario: beans runs inside the shell

- **WHEN** a developer runs `beans version` inside `nix develop`
- **THEN** the command succeeds and reports a `github.com/hmans/beans` version, with no
  prior manual install

### Requirement: Plain-nix multi-system flake

The flake SHALL enumerate supported systems with plain nix — a `systems` list iterated by
a `forAllSystems` helper (e.g. `nixpkgs.lib.genAttrs`) — and SHALL NOT depend on
`flake-utils`. Supported systems SHALL include `x86_64-linux`, `aarch64-linux`,
`x86_64-darwin`, and `aarch64-darwin`. Inputs SHALL be `nixpkgs` (nixos-unstable) and
`nixvim` with `inputs.nixpkgs.follows = "nixpkgs"`, and a `flake.lock` SHALL be committed.

#### Scenario: No flake-utils dependency

- **WHEN** the flake inputs and outputs are inspected
- **THEN** `flake-utils` appears nowhere, and per-system outputs are produced by iterating
  the `systems` list

#### Scenario: Reproducible via committed lock

- **WHEN** the repository is checked out fresh
- **THEN** a committed `flake.lock` pins `nixpkgs` and `nixvim` so `nix develop` resolves
  reproducibly

### Requirement: Reload and test helpers

The editor configuration SHALL bind `<leader>rr` to a `_G.reload_beans()` helper that
clears `package.loaded` entries matching `^beans` and re-sources `plugin/` and `after/`,
and SHALL bind `<leader>rt` to run
`PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}`. The editor
SHALL include `plenary.nvim` and `nvim-treesitter.withAllGrammars`, and configure
`lua_ls` with `vim`, `describe`, `it`, `before_each`, and `after_each` as known globals.

#### Scenario: Hot reload without restarting nvim

- **WHEN** the developer edits a `lua/beans/*.lua` file and presses `<leader>rr`
- **THEN** all `^beans` modules are cleared from `package.loaded` and re-sourced, so the
  next call uses the edited code

#### Scenario: Run the test suite from the editor

- **WHEN** the developer presses `<leader>rt`
- **THEN** the plenary busted runner executes `tests/` with `tests/minimal_init.lua`

### Requirement: Scratch fixture project

The environment SHALL provide a scratch fixture at `.dev/scratch/` that has already had
`beans init` run, so the real TUI → `$EDITOR` → nvim loop can be exercised by hand. The
`.dev/` directory SHALL be git-ignored.

#### Scenario: Ready-to-use scratch project

- **WHEN** a developer changes into `.dev/scratch/` inside the dev shell
- **THEN** a `.beans/` project already exists and `beans tui` operates against it
