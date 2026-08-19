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

raw=$(nvim --headless \
  -c "PlenaryBustedDirectory ${DIR} {minimal_init = 'tests/minimal_init.lua'}" 2>&1)
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
