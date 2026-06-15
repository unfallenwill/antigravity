#!/usr/bin/env bash
# Resolve a hub-channel Antigravity version to its Linux tarball URLs, by
# listing Google's public GCS bucket (which is listable).
#
# Usage: resolve-version.sh <version>
# Prints three lines:
#   <version>       (echoed back, e.g. 2.1.4)
#   <linux-x64 url>
#   <linux-arm url>
set -euo pipefail
VER="${1:?version required (e.g. 2.1.4)}"
BASE="https://storage.googleapis.com/antigravity-public"

xml="$(curl -fsSL "${BASE}/?prefix=antigravity-hub/&delimiter=/")"

# Lines look like: <Prefix>antigravity-hub/2.1.4-6481382726303744/</Prefix>
# The trailing dash after the version prevents 2.0.1 matching 2.0.10, etc.
bid="$(printf '%s\n' "$xml" \
  | grep -oE "antigravity-hub/${VER}-[0-9]+/" \
  | sed -E "s#.*antigravity-hub/${VER}-([0-9]+)/.*#\1#" \
  | sort -n \
  | tail -1)"

[ -n "$bid" ] || { echo "version ${VER} not found in hub bucket" >&2; exit 1; }

ux="${BASE}/antigravity-hub/${VER}-${bid}/linux-x64/Antigravity.tar.gz"
ua="${BASE}/antigravity-hub/${VER}-${bid}/linux-arm/Antigravity.tar.gz"

# Sanity: confirm the object actually exists.
code="$(curl -fsSL -o /dev/null -w '%{http_code}' -I "$ux" || true)"
[ "$code" = "200" ] || { echo "x64 tarball not reachable (HTTP $code): $ux" >&2; exit 1; }

printf '%s\n%s\n%s\n' "$VER" "$ux" "$ua"
