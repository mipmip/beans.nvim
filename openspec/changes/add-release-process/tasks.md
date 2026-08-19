## 1. Version, changelog & docs (beans.nvim-0nqc)

- [ ] 1.1 Add a `VERSION` file containing `0.1.0`.
- [ ] 1.2 Expose `require("beans").version` (read from `VERSION`, or a literal kept in sync
  by `release.sh`); report it in `:checkhealth beans`.
- [ ] 1.3 Add `CHANGELOG.md` (Keep a Changelog) with an `[Unreleased]` section summarising
  work to date (milestones 01–07).
- [ ] 1.4 Add `RELEASING.md`: the release procedure and the pre-1.0 semver note (breaking →
  minor; major = deliberate 1.0.0).

## 2. Release automation (beans.nvim-xqrz)

- [ ] 2.1 Add `gum` to the flake devShell.
- [ ] 2.2 Write `scripts/release.sh`: preflight gates (see §3) → `gum choose
  major/minor/patch` → compute next semver from `VERSION` → `gum confirm`.
- [ ] 2.3 On confirm: update `VERSION`; roll `[Unreleased]` into `[vX.Y.Z] - <date>` and add
  a fresh `[Unreleased]`.
- [ ] 2.4 `jj commit -m "release vX.Y.Z"`, set `main`, `jj git push`.
- [ ] 2.5 `git tag vX.Y.Z <rev>` and `git push origin vX.Y.Z` (through the colocated git,
  since `jj git push` does not push tags).
- [ ] 2.6 `gh release create vX.Y.Z` with notes extracted from the new CHANGELOG section.
- [ ] 2.7 No `release.yml` workflow (decision B); document that `gh` auth is required.

## 3. Plugin QA gates (beans.nvim-k534)

- [ ] 3.1 Add a minimal-install smoke test: clean nvim (no dev flake), add plugin to rtp,
  `require("beans").setup()`, assert `:BeanWizard`/`:Bean` exist and detection attaches on a
  bean buffer.
- [ ] 3.2 Add `.luacheckrc` and make `luacheck lua/ tests/` pass.
- [ ] 3.3 Add a `doc/` helptags freshness check.
- [ ] 3.4 Wire the smoke test, `luacheck`, and the helptags check into `ci.yml`.
- [ ] 3.5 `release.sh` preflight runs all gates: clean/up-to-date `main`, `nix flake check`,
  `scripts/test.sh`, `stylua --check`, `luacheck`, minimal-install smoke, helptags freshness.

## 4. Verification

- [ ] 4.1 Full suite green (`scripts/test.sh tests/`), stylua + luacheck clean, smoke passes.
- [ ] 4.2 Dry-run `release.sh` in a scratch clone (or with the publish steps stubbed) to
  confirm the bump/changelog/tag flow; do NOT cut a real `v0.1.0` until the maintainer opts in.
- [ ] 4.3 `require("beans").version` and `:checkhealth beans` report `0.1.0`.
