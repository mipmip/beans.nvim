## Why

The `mipmip/beans.nvim` GitHub repository has no topics set
(`repositoryTopics: null`), so it is invisible to topic-based discovery and search
on GitHub. For the public release (milestone `09 public release`, bean
`beans.nvim-kbp1`) the repo should carry a curated set of the most relevant topics.

## What Changes

- Set a curated list of GitHub topics on the repository via
  `gh repo edit mipmip/beans.nvim --add-topic <t>` (or the API).
- Recommended set (all lowercase, hyphen-separated, within GitHub's ≤20 topics /
  ≤35 chars-each limits), chosen for how people actually search for a plugin like
  this:
  - `neovim`, `neovim-plugin`, `nvim` — the platform and the two most-searched
    plugin tags.
  - `lua` — implementation language / ecosystem filter.
  - `beans`, `issue-tracker`, `project-management` — the problem domain (a
    companion to the Beans flat-file issue tracker).
  - `markdown` — the file format it edits.
- A tight core set of 8 topics is used; lower-signal format tags (`yaml`,
  `frontmatter`) are deliberately omitted to keep the signal high.
- No repository description change is in scope (a description already exists); this
  change only populates topics.

## Capabilities

### New Capabilities
- `repo-metadata`: The public GitHub repository metadata (starting with topics)
  SHALL be curated so the project is discoverable via GitHub topic search.

### Modified Capabilities
<!-- None. -->

## Impact

- GitHub repository settings only (`mipmip/beans.nvim` topics). No code, no files in
  the working tree, no runtime behaviour. Requires an authenticated `gh` with repo
  admin rights.
