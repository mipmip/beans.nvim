---
# beans.nvim-85rb
title: Nix flake dev environment (plain nix, multi-system)
status: completed
type: epic
priority: normal
created_at: 2026-08-19T13:13:12Z
updated_at: 2026-08-19T13:36:36Z
parent: beans.nvim-j5je
---

Model closely on mipmip/vim-mimosa/flake.nix but with plain nix for supported
systems (NO flake-utils) — iterate a `systems` list and build per-system outputs.

## Scope
- Inputs: nixpkgs (nixos-unstable) + nixvim with `inputs.nixpkgs.follows`.
- Build editor via `nixvim.legacyPackages.<system>.makeNixvimWithModule`.
- extraPlugins: plenary-nvim, nvim-treesitter.withAllGrammars.
- extraConfigLua prepends plugin source to runtimepath from `BEANS_NVIM_DEV_PATH`,
  falling back to the flake path.
- `_G.reload_beans()` bound to <leader>rr; <leader>rt runs PlenaryBustedDirectory.
- lua_ls with vim/describe/it/before_each/after_each globals.
- devShells.default: nvim pkg, lua-language-server, stylua, and the `beans` binary.
- shellHook: export BEANS_NVIM_DEV_PATH, redirect XDG_*_HOME into .dev/, mkdir, banner.
- apps.default -> built nvim.
- Provide `beans` in the shell: verify nixpkgs packaging; else buildGoModule pinned to
  a release tag (module github.com/hmans/beans). Env must be self-contained.
- Scratch fixture at .dev/scratch/ with `beans init` already run.

## Acceptance
- [ ] `nix develop` opens isolated nvim; real user config untouched.
- [ ] `beans` runs inside the shell without extra installs.
- [ ] `flake.nix` uses plain nix per-system (no flake-utils); flake.lock committed.

Briefing §10, verify item §14.3.

## Summary of Changes

- `flake.nix`: plain-nix multi-system (x86_64/aarch64 linux+darwin via `genAttrs`,
  no flake-utils); NixVim via `makeNixvimWithModule`; `beans` (nixpkgs v0.4.2) in both
  the editor env and the devShell; reload/test keymaps; XDG isolation into `.dev/`;
  `apps.default` for `nix run`.
- `flake.lock` committed. Verified: `nix develop` opens an isolated nvim and
  `beans version` prints 0.4.2 inside the shell.
