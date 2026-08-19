#!/usr/bin/env bash
# Minimal-install smoke test.
#
# Loads beans.nvim in a CLEAN Neovim (no user config, no dev flake) and asserts
# it actually activates — the "works in dev, broken for users" guard. Use a PLAIN
# nvim, NOT the flake's dev editor (which pre-wires setup()); override the binary
# with SMOKE_NVIM if `nvim` on PATH is the dev editor.
set -euo pipefail

NVIM="${SMOKE_NVIM:-nvim}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/.beans"
printf 'beans:\n    path: .beans\n' > "$tmp/.beans.yml"
cat > "$tmp/.beans/beans-0001--smoke.md" <<'EOF'
---
# beans-0001
title: smoke
status: todo
type: task
---

body
EOF

"$NVIM" --clean --headless \
  --cmd "set runtimepath^=$ROOT" \
  -c "lua require('beans').setup()" \
  -c "edit $tmp/.beans/beans-0001--smoke.md" \
  -c "lua vim.wait(200)" \
  -c "lua assert(vim.fn.exists(':BeanWizard') == 2, ':BeanWizard command missing')" \
  -c "lua assert(vim.fn.exists(':Bean') == 2, ':Bean command missing')" \
  -c "lua assert(vim.b.beans ~= nil, 'detection did not attach (vim.b.beans is nil)')" \
  -c "lua assert(require('beans').version ~= 'unknown', 'version did not resolve')" \
  -c "qa!"

echo "smoke: OK — activated, detection attached, version $(cat "$ROOT/VERSION")"
