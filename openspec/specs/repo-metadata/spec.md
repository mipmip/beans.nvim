# repo-metadata Specification

## Purpose
TBD - created by archiving change populate-github-topics. Update Purpose after archive.
## Requirements
### Requirement: Repository has curated discovery topics

The `mipmip/beans.nvim` GitHub repository SHALL have a curated set of topics that
identify its platform (Neovim), language (Lua), and problem domain (the Beans
issue tracker), so it is discoverable via GitHub topic search. Topics MUST conform
to GitHub's rules: lowercase, hyphen-separated, ≤35 characters each, ≤20 total.

#### Scenario: Topics are present and valid

- **WHEN** the repository metadata is queried (`gh repo view --json repositoryTopics`)
- **THEN** `repositoryTopics` is non-empty
- **AND** it includes at least `neovim`, `neovim-plugin`, `lua`, and `beans`
- **AND** every topic is lowercase, ≤35 characters, and the list has ≤20 entries

#### Scenario: Topics reflect the problem domain

- **WHEN** a user searches GitHub topics for issue-tracking or project-management
  Neovim tooling
- **THEN** the repository surfaces via at least one domain topic
  (`issue-tracker` or `project-management`)

