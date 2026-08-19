## 1. dev-environment (beans.nvim-85rb)

- [ ] 1.1 Create `flake.nix` inputs: `nixpkgs` (nixos-unstable) and `nixvim` with
      `inputs.nixpkgs.follows = "nixpkgs"`; no `flake-utils`.
- [ ] 1.2 Add a plain-nix `systems` list (`x86_64-linux`, `aarch64-linux`,
      `x86_64-darwin`, `aarch64-darwin`) and a `forAllSystems` helper
      (`nixpkgs.lib.genAttrs systems`); build every output by iterating it.
- [ ] 1.3 Build the editor with `nixvim.legacyPackages.<system>.makeNixvimWithModule`;
      set `extraPlugins = [ plenary-nvim (nvim-treesitter.withAllGrammars) ]`.
- [ ] 1.4 Add `extraConfigLua` that prepends `$BEANS_NVIM_DEV_PATH` (fallback: the
      flake's own path) to `runtimepath`.
- [ ] 1.5 Configure `lua_ls` with `vim`, `describe`, `it`, `before_each`, `after_each`
      as known globals.
- [ ] 1.6 Define `_G.reload_beans()` (clear `package.loaded` matching `^beans`, re-source
      `plugin/` and `after/`) bound to `<leader>rr`; bind `<leader>rt` to
      `PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}`.
- [ ] 1.7 Add `beans` to the editor env and to `devShells.default` via `pkgs.beans`
      (nixpkgs; verified `github.com/hmans/beans` v0.4.2). Document the `buildGoModule`
      fallback pinned to a release tag as a comment.
- [ ] 1.8 `devShells.default` also provides the built nvim, `lua-language-server`, and
      `stylua`.
- [ ] 1.9 `shellHook`: export `BEANS_NVIM_DEV_PATH="$(pwd)"`; redirect `XDG_CONFIG_HOME`,
      `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` under `$(pwd)/.dev/`;
      `mkdir -p` them; print a short help banner.
- [ ] 1.10 Add `apps.default` pointing at the built nvim (`nix run`).
- [ ] 1.11 Create `.dev/scratch/` with `beans init` already run for the manual
      TUI → `$EDITOR` → nvim loop.
- [ ] 1.12 Commit `flake.lock`; verify `nix develop` opens an isolated nvim and `beans
      version` works inside the shell.

## 2. project-scaffolding (beans.nvim-qmll)

- [ ] 2.1 Create the `lua/beans/` module tree of §9 as loadable stubs:
      `init, config, health, project, detect, cli, schema, frontmatter, completion,
      actions`, `wizard/{init,ui}`, `wizard/steps/{enum,tags,parent}`.
- [ ] 2.2 Add `plugin/beans.lua` entry (guarded load); create `after/` if the reload
      helper needs it.
- [ ] 2.3 Ensure `require("beans").setup()` does not error, including when `beans` is
      missing from `PATH` (degrade to a health-check concern).
- [ ] 2.4 Add `stylua.toml`; ensure the whole skeleton passes `stylua --check`.
- [ ] 2.5 Add `.gitignore` that excludes `.dev/`.
- [ ] 2.6 Add a `README.md` skeleton and a `doc/beans.txt` vimdoc stub.
- [ ] 2.7 Create the `tests/` skeleton: `minimal_init.lua`, `fixtures/` (incl. a
      `fake-beans` placeholder), `helpers/` (`project.lua`, `child.lua` stubs), and
      placeholder `*_spec.lua` files per §9.
- [ ] 2.8 Confirm `plenary.nvim` is test-only (never a runtime dependency of the plugin).
