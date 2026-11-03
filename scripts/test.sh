#!/usr/bin/env bash
# Run the plenary suite and derive the exit code from the reported results.
#
# PlenaryBustedDirectory's own process exit code is unreliable when a spec blocks
# the loop with vim.system():wait() (the golden layer shells out to the real
# beans CLI): the child nvim can exit non-zero even when every test passes. So we
# parse the summary instead — the source of truth is "Failed : N" / "Errors : N".
#
# Usage: scripts/test.sh [test-dir]   (default: tests/)
set -uo pipefail

DIR="${1:-tests/}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The *parent* nvim needs plenary on its runtimepath: it is the one that defines
# :PlenaryBustedDirectory. Inside `nix develop` the dev editor ships it; outside,
# CI vendors it into .deps/plenary.nvim. Without this the -c command fails with
# E492 and headless nvim idles forever instead of exiting.
rtp=(--cmd "lua vim.opt.runtimepath:prepend('${ROOT}')")
if [ -d "${ROOT}/.deps/plenary.nvim" ]; then
  rtp+=(--cmd "lua vim.opt.runtimepath:prepend('${ROOT}/.deps/plenary.nvim')")
fi

# Hard cap so a stuck child can never hold a CI runner for hours. Redirect stdin
# for the same reason: a headless nvim that blocks on input never returns.
timer=()
if command -v timeout > /dev/null 2>&1; then
  timer=(timeout -k 10 "${NVIM_TIMEOUT:-300}")
fi

raw=$("${timer[@]}" nvim --headless "${rtp[@]}" \
  -c "PlenaryBustedDirectory ${DIR} {minimal_init = '${ROOT}/tests/minimal_init.lua'}" \
  2>&1 < /dev/null)
status=$?
echo "$raw"

# Strip ANSI colour codes before parsing (plenary colourises its summary).
out=$(printf '%s' "$raw" | sed -E 's/\x1b\[[0-9;]*m//g')

fails=$(printf '%s' "$out" | grep -oE "Failed : +[0-9]+" | grep -oE "[0-9]+$" | awk '{s+=$1} END{print s+0}')
errs=$(printf '%s' "$out" | grep -oE "Errors : +[0-9]+" | grep -oE "[0-9]+$" | awk '{s+=$1} END{print s+0}')
succ=$(printf '%s' "$out" | grep -cE "Success: ")

if [ "$succ" -eq 0 ]; then
  echo "test.sh: no tests appear to have run (exit ${status})" >&2
  exit 1
fi
if [ "$fails" -gt 0 ] || [ "$errs" -gt 0 ]; then
  echo "test.sh: ${fails} failed, ${errs} errored" >&2
  exit 1
fi

echo "test.sh: all tests passed (${succ} spec files)"
exit 0
