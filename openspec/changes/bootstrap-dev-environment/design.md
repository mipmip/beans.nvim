## Context

The plugin will be developed and tested against a NixVim editor that must never leak
into the developer's real config. The briefing points at
`mipmip/vim-mimosa/flake.nix` as the reference shape: `makeNixvimWithModule`, an
`extraConfigLua` that prepends the plugin source to `runtimepath`, reload helpers, and
a `shellHook` that redirects the XDG dirs into `.dev/`. Two deviations from that
reference are required here: supported systems are enumerated with plain nix (no
`flake-utils`), and the `beans` CLI must be present in the shell.

## Goals / Non-Goals

**Goals:**

- `nix develop` opens an isolated nvim; the developer's `~/.config/nvim` is untouched.
- `beans` runs inside the shell with zero extra installation steps.
- Supported systems are produced by iterating a plain `systems` list — no `flake-utils`.
- `flake.lock` is committed so the environment is reproducible.
- The `lua/beans/` module tree of §9 exists as loadable stubs; `require("beans")` and
  `setup()` succeed even when `beans` is absent from `PATH`.
- `stylua --check` passes on the skeleton; `.dev/` is git-ignored.

**Non-Goals:**

- Any real plugin behaviour (detection, wizard, completion) — later milestones.
- CI wiring and the full test matrix — Milestone 05.
- Packaging beans.nvim itself as a Nix package for end users.

## Decisions

- **Plain-nix multi-system, no `flake-utils`.** Define
  `systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]` and a
  small `forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system)` helper.
  Every output (`devShells`, `packages`/`apps`) is built with
  `forAllSystems (system: ...)`. This keeps the dependency graph minimal and is an
  explicit briefing requirement.
- **Editor via `nixvim.legacyPackages.<system>.makeNixvimWithModule`** with
  `extraPlugins = [ plenary-nvim (nvim-treesitter.withAllGrammars) ]`, `lua_ls`
  configured with `vim`, `describe`, `it`, `before_each`, `after_each` as known globals,
  and `extraConfigLua` that prepends `$BEANS_NVIM_DEV_PATH` (falling back to the flake's
  own path) to `runtimepath`.
- **`beans` comes straight from nixpkgs.** Verified: `nixpkgs#beans` resolves to
  `github.com/hmans/beans` v0.4.2. Add `pkgs.beans` to the dev shell and to the editor's
  environment. A `buildGoModule` derivation is therefore **not** needed; if nixpkgs ever
  lags a required release, fall back to `buildGoModule` pinned to a `github.com/hmans/beans`
  release tag.
- **Reload/test helpers.** `_G.reload_beans()` clears `package.loaded` entries matching
  `^beans` and re-sources `plugin/` and `after/`, bound to `<leader>rr`. `<leader>rt`
  runs `PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}`.
- **XDG isolation via `shellHook`.** Export `BEANS_NVIM_DEV_PATH="$(pwd)"`; redirect
  `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` under
  `$(pwd)/.dev/`; `mkdir -p` them; print a short help banner. `.dev/` is git-ignored.
- **`apps.default`** points at the built nvim so `nix run` launches the isolated editor.
- **Module tree as stubs.** Each `lua/beans/*.lua` returns an empty-ish module table so
  `require` never errors; `config.lua` may already carry the default table shape. This
  lets later milestones fill behaviour without restructuring.

## Risks / Trade-offs

- **nixpkgs `beans` version drift.** The pinned nixpkgs may carry a `beans` older/newer
  than upstream `main` referenced by the briefing. Mitigation: pin via `flake.lock`, and
  keep the `buildGoModule` escape hatch documented for a specific tag.
- **NixVim API churn.** `makeNixvimWithModule` and option names can change across nixvim
  revisions. Mitigation: pin nixvim in `flake.lock` and `inputs.nixpkgs.follows`.
- **`withAllGrammars` size.** Pulling all treesitter grammars enlarges the closure but
  matches the reference flake and avoids per-grammar breakage in tests. Acceptable for a
  dev-only shell.
- **Plain-nix boilerplate.** Slightly more verbose than `flake-utils`, but removes an
  input and is the mandated approach.
