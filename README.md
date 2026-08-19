# beans.nvim

A Neovim companion for [Beans](https://github.com/hmans/beans), a CLI-based
flat-file issue tracker. When the Beans TUI opens a freshly created bean in your
`$EDITOR`, beans.nvim pops a small near-cursor wizard so you can set `status`,
`type`, `priority`, `tags` and `parent` with single keystrokes, then drops you
into the body in insert mode — no YAML by hand, no CLI round-trip.

> **Status: alpha / under construction.** This repository is being built
> milestone by milestone. See the roadmap in `.beans/` (`beans list`) and the
> work packages in `openspec/`. The full design lives in
> [`beans-nvim-briefing.md`](beans-nvim-briefing.md).

## Installation

_Documented in Milestone 05._

## The wizard

Five steps, in order: `status` → `type` → `priority` → `tags` → `parent`.

Note the deliberate inconsistency between step kinds (documented fully in
Milestone 05): **enum steps select by letter** (one keystroke = select + advance),
while **tags and parent select by filtering/typing**.

## Configuration

`require("beans").setup()` with no arguments yields the full intended
experience. The complete default table is documented in
[`beans-nvim-briefing.md`](beans-nvim-briefing.md) §7.3.

## Development

```sh
nix develop      # isolated NixVim + the beans CLI, nothing touches your config
nvim             # start the isolated editor
# inside nvim: <Space>rt runs the test suite, <Space>rr reloads the plugin
```

## License

See [LICENSE](LICENSE).
