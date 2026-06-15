#!/usr/bin/env bash
# Repackage an official Antigravity-family Linux tarball into .deb and .rpm.
#
# Inputs (env):
#   PRODUCT  (required)  antigravity | antigravity-ide
#   VERSION  (required)  upstream version, e.g. 2.1.4
#   ARCH     (required)  x64 | arm
#   CHANNEL  (optional)  hub (default) | stable | custom
#   URL_X64  (optional)  explicit x64 tarball URL (stable/custom)
#   URL_ARM  (optional)  explicit arm tarball URL (stable/custom)
#
# For PRODUCT=antigravity + CHANNEL=hub the build-id is resolved from the
# listable public GCS bucket, so callers only need VERSION. All other cases
# require explicit URL_X64 / URL_ARM for each built arch.
set -euo pipefail

PRODUCT="${PRODUCT:?PRODUCT is required (antigravity | antigravity-ide)}"
VERSION="${VERSION:?VERSION is required}"
ARCH="${ARCH:?ARCH is required (x64 | arm)}"
CHANNEL="${CHANNEL:-hub}"
URL_X64="${URL_X64:-}"
URL_ARM="${URL_ARM:-}"

# --- Product profile ---------------------------------------------------------
case "$PRODUCT" in
  antigravity)
    PKG_NAME=antigravity;  P_BIN=antigravity;      P_INST=/opt/antigravity
    P_DISPLAY="Antigravity"; P_GENERIC="Agentic Desktop Application"
    P_ICON=antigravity;    P_WMCLASS=Antigravity;  P_SCHEME=antigravity ;;
  antigravity-ide)
    PKG_NAME=antigravity-ide; P_BIN=antigravity-ide; P_INST=/opt/antigravity-ide
    P_DISPLAY="Antigravity IDE"; P_GENERIC="Code Editor"
    P_ICON=antigravity-ide; P_WMCLASS=antigravity-ide; P_SCHEME=antigravity-ide ;;
  *) echo "Unknown PRODUCT: $PRODUCT" >&2; exit 1 ;;
esac

# CHANNEL=hub means "resolve the official source for this product":
#   antigravity     -> listable GCS bucket (resolve-version.sh)
#   antigravity-ide -> the IDE's auto-updater API (resolve-ide.sh), always latest
# stable/custom take explicit URL_X64 / URL_ARM.

case "$ARCH" in
  x64) DEB_ARCH=amd64; RPM_ARCH=x86_64 ;;
  arm) DEB_ARCH=arm64; RPM_ARCH=aarch64 ;;
  *) echo "ARCH must be x64 or arm (got: $ARCH)" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# render(): expand ${VAR} from the environment. Needs only perl (always present).
render() { perl -pe 's/\$\{(\w+)\}/defined $ENV{$1} ? $ENV{$1} : ""/ge' "$1" > "$2"; }

# --- Resolve the tarball URL for this arch -----------------------------------
if [ "$ARCH" = x64 ] && [ -n "$URL_X64" ]; then
  URL="$URL_X64"
elif [ "$ARCH" = arm ] && [ -n "$URL_ARM" ]; then
  URL="$URL_ARM"
elif [ "$CHANNEL" = hub ]; then
  echo ">> Resolving official source for $P_DISPLAY ..."
  case "$PRODUCT" in
    antigravity)     mapfile -t RES < <("$ROOT/packaging/resolve-version.sh" "$VERSION") ;;
    antigravity-ide) mapfile -t RES < <("$ROOT/packaging/resolve-ide.sh") ;;
  esac
  VERSION="${RES[0]}"          # resolver prints the (possibly discovered) version
  [ "$ARCH" = x64 ] && URL="${RES[1]}" || URL="${RES[2]}"
  BUILD_ID="$(printf '%s' "${RES[1]}" | sed -E 's#.*/[0-9]+\.[0-9]+\.[0-9]+-([0-9]+)/.*#\1#' || true)"
else
  echo "No URL provided for ARCH=$ARCH and CHANNEL=$CHANNEL" >&2; exit 1
fi
[ -n "${BUILD_ID:-}" ] || BUILD_ID="manual"

echo ">> $P_DISPLAY $VERSION   arch=$ARCH ($DEB_ARCH/$RPM_ARCH)   channel=$CHANNEL"
echo ">> URL: $URL"

# --- Download + extract ------------------------------------------------------
curl -fsSL "$URL" -o "$WORK/antigravity.tar.gz"
mkdir -p "$WORK/ex"
tar -xzf "$WORK/antigravity.tar.gz" -C "$WORK/ex"
TOPDIR="$(find "$WORK/ex" -mindepth 1 -maxdepth 1 -type d | head -1)"
[ -d "$TOPDIR" ] || { echo "tarball has no top-level directory" >&2; exit 1; }
echo ">> upstream top-level dir: $(basename "$TOPDIR")"

# --- Stage payload (= ${P_INST}) ---------------------------------------------
rm -rf "$BUILD"; mkdir -p "$BUILD/payload" "$BUILD/scripts" "$BUILD/icons"
shopt -s dotglob nullglob
mv "$TOPDIR"/* "$BUILD/payload/"
shopt -u dotglob nullglob
[ -f "$BUILD/payload/chrome-sandbox" ] && chmod 4755 "$BUILD/payload/chrome-sandbox"
chmod +x "$BUILD/payload/$P_BIN" 2>/dev/null || true

# --- Render templates + stage icons ------------------------------------------
NFPM_ARCH="$DEB_ARCH"
export PKG_NAME P_BIN P_INST P_DISPLAY P_GENERIC P_ICON P_WMCLASS P_SCHEME \
       VERSION BUILD_ID NFPM_ARCH

render "$ROOT/packaging/templates/nfpm.yaml.tmpl" "$BUILD/nfpm.yaml"
render "$ROOT/packaging/templates/desktop.tmpl"   "$BUILD/${PKG_NAME}.desktop"
render "$ROOT/packaging/templates/wrapper.tmpl"   "$BUILD/wrapper"
render "$ROOT/packaging/templates/postinst.tmpl"  "$BUILD/scripts/postinst"
render "$ROOT/packaging/templates/prerm.tmpl"     "$BUILD/scripts/prerm"
render "$ROOT/packaging/templates/postrm.tmpl"    "$BUILD/scripts/postrm"
chmod +x "$BUILD/wrapper" "$BUILD/scripts/postinst" "$BUILD/scripts/prerm" "$BUILD/scripts/postrm"

cp -R "$ROOT/packaging/icons/${PKG_NAME}/hicolor" "$BUILD/icons/hicolor"

# --- Build .deb and .rpm -----------------------------------------------------
mkdir -p "$DIST"
DEB_NAME="${PKG_NAME}_${VERSION}_${DEB_ARCH}.deb"
RPM_NAME="${PKG_NAME}-${VERSION}.${RPM_ARCH}.rpm"

( cd "$ROOT" && nfpm package --config build/nfpm.yaml --packager deb \
    --target "$DIST/$DEB_NAME" )
( cd "$ROOT" && nfpm package --config build/nfpm.yaml --packager rpm \
    --target "$DIST/$RPM_NAME" )

( cd "$DIST" && sha256sum "$DEB_NAME" "$RPM_NAME" \
    > "checksums_${PKG_NAME}_${VERSION}_${DEB_ARCH}.txt" )

echo ">> Built:"
ls -lh "$DIST/$DEB_NAME" "$DIST/$RPM_NAME" "$DIST/checksums_${PKG_NAME}_${VERSION}_${DEB_ARCH}.txt"
