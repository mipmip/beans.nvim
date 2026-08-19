## 1. Set topics

- [x] 1.1 Confirm `gh auth status` and that the account has admin rights on `mipmip/beans.nvim`.
- [x] 1.2 Set the curated topics: `gh repo edit mipmip/beans.nvim --add-topic neovim --add-topic neovim-plugin --add-topic nvim --add-topic lua --add-topic beans --add-topic issue-tracker --add-topic project-management --add-topic markdown`

## 2. Verify

- [x] 2.1 `gh repo view mipmip/beans.nvim --json repositoryTopics` shows the expected non-empty set.
- [x] 2.2 Confirm the list has ≤20 entries and each topic is lowercase and ≤35 chars (8 entries, all lowercase, longest is `project-management` at 18 chars).
