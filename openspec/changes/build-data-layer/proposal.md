## Why

beans.nvim's wizard (Milestone 03) can only feel instant if the mechanical layer
beneath it is correct and non-blocking. That layer has three jobs: decide whether a
buffer is a bean at all, read Beans' vocabularies and candidate lists without stalling
the editor, and mutate frontmatter byte-for-byte the way Beans itself would. Getting
this wrong is expensive: a false-positive detection puts keymaps on every markdown
file, a blocking read stutters the UI, and a malformed frontmatter write produces a
file Beans will not round-trip. This milestone builds that foundation so the wizard has
nothing left to worry about except UX.

## What Changes

- Add project-root discovery and bean detection that attaches plugin state
  (`vim.b.beans`) and buffer-local keymaps only to real bean buffers, via two
  independent (OR'd) checks — path and content — with a defined auto-start heuristic.
- Add an asynchronous CLI wrapper over `vim.system` plus a schema layer that discovers
  Beans' vocabularies from `beans update --help`, computes mnemonics dynamically,
  prefetches reads on buffer open, and caches them per project root.
- Add a pure, heavily-tested frontmatter engine that sets, inserts, and clears scalars
  and list values in Beans' canonical field order while preserving the `# <id>` comment
  and timestamps.
- Add layer-1 unit specs (`plenary.nvim`) for every module above, driven by a
  `fake-beans` stub so the suite is hermetic.

## Capabilities

### New Capabilities
- `bean-detection`: project-root discovery, is-a-bean checks, `vim.b.beans` attachment,
  the auto-start heuristic, and basic `:checkhealth beans` diagnostics.
- `cli-schema`: async `vim.system` CLI wrapper, vocabulary discovery from help text,
  dynamic mnemonic assignment, and prefetch/caching of reads.
- `frontmatter-engine`: pure line-list parse/edit of YAML frontmatter honouring Beans'
  canonical field order.

### Modified Capabilities
<!-- None: this is the first milestone to introduce runtime specs. -->

## Impact

- New Lua modules: `lua/beans/project.lua`, `lua/beans/detect.lua`,
  `lua/beans/cli.lua`, `lua/beans/schema.lua`, `lua/beans/frontmatter.lua`, and
  `:checkhealth` support in `lua/beans/health.lua`.
- New tests: `tests/frontmatter_spec.lua`, `tests/schema_spec.lua`,
  `tests/project_spec.lua`, `tests/detect_spec.lua`, plus the `tests/fixtures/fake-beans`
  stub and `tests/helpers/project.lua`.
- Runtime dependency footprint stays zero; `plenary.nvim` remains test-only.
- Consumes the external `beans` CLI for reads only; writes never shell out (see design).
- Downstream: Milestone 03 (wizard) depends on all three capabilities; Milestone 05
  (golden equivalence) depends on `frontmatter-engine`.
