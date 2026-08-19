---
# beans.nvim-q6z8
title: Wizard float sizes to content (wider + taller)
status: completed
type: feature
created_at: 2026-08-19T20:05:45Z
updated_at: 2026-08-19T20:05:45Z
---

The wizard/parent float clipped long footers and candidate lines at a fixed 60 cols.

## Change
- ui.lua: float now sizes width to the widest rendered line (min 24) capped at
  window.max_width, and height to content capped at window.max_height — computed per
  render, so enum steps stay compact while parent/long steps grow.
- Defaults raised: window.max_width 60→80, max_height 12→16 (config.lua + briefing §7.3).

## Verified
- enum step ~57 cols (compact); parent step grows to fit a 73-col line; footer no longer
  clipped. Full suite green, stylua clean.
