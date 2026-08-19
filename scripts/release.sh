#!/usr/bin/env bash
# Cut a beans.nvim release, manually and gated.
#
# A plugin release is just a git tag. This script runs the QA gates, asks for a
# major/minor/patch bump with gum, updates VERSION + CHANGELOG, commits with jj,
# pushes a git tag through the colocated git, and creates the GitHub release from
# the CHANGELOG. See RELEASING.md. Requires: gum, gh (authenticated), a clean
# nvim for the smoke test (SMOKE_NVIM to override), and the nix devShell tools.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

die() {
  echo "release: $1" >&2
  exit 1
}

# ---- preflight gates (abort before touching anything) ----------------------
echo "==> preflight"

[ -z "$(jj status --no-pager 2>/dev/null | grep -E '^(A|M|D) ')" ] \
  || die "working copy is dirty — commit or discard first"

jj git fetch >/dev/null 2>&1 || true

echo "  - nix flake check"
nix flake check

echo "  - test suite"
nix develop --command bash scripts/test.sh tests/ >/dev/null

echo "  - stylua"
nix develop --command stylua --check lua/ tests/ plugin/

echo "  - luacheck"
nix develop --command luacheck lua/ tests/ plugin/ >/dev/null

echo "  - minimal-install smoke"
bash scripts/smoke.sh >/dev/null

echo "  - helptags freshness"
tmp_doc="$(mktemp -d)"
cp doc/*.txt "$tmp_doc/"
nvim --clean --headless -c "helptags $tmp_doc" -c "qa!" >/dev/null 2>&1
diff -q doc/tags "$tmp_doc/tags" >/dev/null || die "doc/tags is stale — run :helptags doc and commit"
rm -rf "$tmp_doc"

# ---- choose the bump -------------------------------------------------------
current="$(cat VERSION)"
IFS=. read -r major minor patch <<<"$current"

level="$(gum choose --header "Current v${current}. Bump:" major minor patch)"
case "$level" in
  major) next="$((major + 1)).0.0" ;;
  minor) next="${major}.$((minor + 1)).0" ;;
  patch) next="${major}.${minor}.$((patch + 1))" ;;
  *) die "no bump level chosen" ;;
esac

gum confirm "Release v${next} (from v${current})?" || die "aborted"

# ---- bump VERSION + CHANGELOG ---------------------------------------------
date="$(date +%Y-%m-%d)"
echo "$next" >VERSION

# Roll [Unreleased] into a dated [next] section and add a fresh [Unreleased].
awk -v ver="$next" -v date="$date" '
  /^## \[Unreleased\]/ && !done {
    print "## [Unreleased]"
    print ""
    print "## [" ver "] - " date
    done = 1
    next
  }
  { print }
' CHANGELOG.md >CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md

# Extract the notes for this version (between [next] and the next "## [" header).
notes="$(awk -v tag="## [$next]" '
  index($0, tag) == 1 { grab = 1; next }
  /^## \[/ && grab { exit }
  grab { print }
' CHANGELOG.md)"

# ---- commit, tag, publish -------------------------------------------------
jj commit -m "release v${next}"
jj bookmark set main -r @-
jj git push

git tag "v${next}" "$(jj log --no-graph -r @- -T 'commit_id' 2>/dev/null || git rev-parse HEAD)"
git push origin "v${next}"

printf '%s\n' "$notes" | gh release create "v${next}" --title "v${next}" --notes-file -

echo "==> released v${next}"
