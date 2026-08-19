## Context

`mipmip/beans.nvim` has no GitHub topics. This is a one-shot metadata change with no
code impact; a design doc is included only to satisfy the artifact chain and to
record the topic-selection rationale so it is reviewable.

## Goals / Non-Goals

**Goals:**
- Populate a small, high-signal set of topics that maximises discoverability.

**Non-Goals:**
- Changing the repository description (already set).
- Any code, README, or working-tree change.
- Exhaustively listing every conceivable topic — a focused set beats keyword-stuffing.

## Decisions

**Tight core set of 8 topics, well under the 20-topic maximum.** GitHub allows 20,
but a tight, relevant set reads better and avoids diluting signal. Chosen tiers:
- Platform: `neovim`, `neovim-plugin`, `nvim`
- Language: `lua`
- Domain: `beans`, `issue-tracker`, `project-management`
- Format: `markdown`

Alternatives rejected:
- `vim`, `plugin`, `cli`, `tui` — `vim` is misleading (Neovim-only);
  `plugin`/`cli`/`tui` are low-signal generics.
- `yaml`, `frontmatter` — accurate but lower-signal format tags; `markdown` alone
  carries the format dimension without over-tagging.

**Apply via `gh repo edit`.** `gh repo edit mipmip/beans.nvim --add-topic <t>` is the
simplest authenticated path and is idempotent for re-runs.

## Risks / Trade-offs

- **`gh` lacks admin rights / not authenticated** → the apply step fails loudly;
  fallback is setting topics manually in the GitHub UI (Settings → Topics).
- **Topic name typo / invalid topic** → GitHub silently normalises or rejects;
  mitigation is the verification step re-reading `repositoryTopics`.
