#!/usr/bin/env bash
# Resolve an Antigravity IDE stable version + Linux tarball URLs using the
# official releases API consumed by antigravity.google.
#
# Usage: resolve-ide.sh [version]
# Prints three lines:
#   <version>      (latest when the argument is omitted)
#   <linux-x64 url>
#   <linux-arm url>
set -euo pipefail
VER="${1:-}"
API="https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases"
BASE="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable"

mapfile -t release < <("$(dirname "${BASH_SOURCE[0]}")/resolve-release.sh" "$API" "$VER")
ver="${release[0]:-}"
bid="${release[1]:-}"
[ -n "$ver" ] && [ -n "$bid" ] || { echo "invalid release response from $API" >&2; exit 1; }

ux="${BASE}/${ver}-${bid}/linux-x64/Antigravity%20IDE.tar.gz"
ua="${BASE}/${ver}-${bid}/linux-arm/Antigravity%20IDE.tar.gz"

printf '%s\n%s\n%s\n' "$ver" "$ux" "$ua"
