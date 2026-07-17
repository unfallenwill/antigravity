#!/usr/bin/env bash
# Resolve a hub-channel Antigravity version to its Linux tarball URLs using
# the official releases API consumed by antigravity.google.
#
# Usage: resolve-version.sh [version]
# Prints three lines:
#   <version>       (latest when the argument is omitted)
#   <linux-x64 url>
#   <linux-arm url>
set -euo pipefail
VER="${1:-}"
API="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases"
BASE="https://storage.googleapis.com/antigravity-public"

mapfile -t release < <("$(dirname "${BASH_SOURCE[0]}")/resolve-release.sh" "$API" "$VER")
VER="${release[0]:-}"
bid="${release[1]:-}"
[ -n "$VER" ] && [ -n "$bid" ] || { echo "invalid release response from $API" >&2; exit 1; }

ux="${BASE}/antigravity-hub/${VER}-${bid}/linux-x64/Antigravity.tar.gz"
ua="${BASE}/antigravity-hub/${VER}-${bid}/linux-arm/Antigravity.tar.gz"

printf '%s\n%s\n%s\n' "$VER" "$ux" "$ua"
