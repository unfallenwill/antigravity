#!/usr/bin/env bash
# Discover the latest Antigravity IDE stable version + Linux tarball URLs.
#
# Antigravity IDE is a VS Code fork. Its "Check for Updates" menu is wired to a
# hardcoded Cloud Run auto-updater (the product.json `updateUrl` is a dummy
# `https://example.com` that only exists to keep the menu enabled). This script
# queries that real endpoint, the standard VS Code `/api/update` API:
#
#   GET <api>/api/update/<platform>/<quality>/0
#
# Passing commit `0` always returns the latest stable release as JSON, including
# the canonical download `url`.
#
# Usage: resolve-ide.sh
# Prints three lines:
#   <version>      e.g. 2.0.4   (parsed from the download URL)
#   <linux-x64 url>
#   <linux-arm url>
set -euo pipefail
API="https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update"

url_of() { # $1 = platform (linux-x64 | linux-arm64)
  # The API returns the URL with a literal space in "Antigravity IDE.tar.gz";
  # percent-encode it so curl accepts it.
  curl -fsSL "$API/$1/stable/0" | grep -oE '"url":"[^"]*"' \
    | sed 's/^"url":"//; s/"$//; s/ /%20/g'
}

ux="$(url_of linux-x64)"
ua="$(url_of linux-arm64)"
[ -n "$ux" ] || { echo "no linux-x64 url from IDE updater API" >&2; exit 1; }

# Version lives in the URL path: .../stable/<version>-<buildid>/linux-x64/...
ver="$(printf '%s' "$ux" | grep -oE 'stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/' \
  | sed -E 's#stable/([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/#\1#' | head -1)"
[ -n "$ver" ] || { echo "could not parse IDE version from $ux" >&2; exit 1; }

printf '%s\n%s\n%s\n' "$ver" "$ux" "$ua"
