#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

export VERSION="${VERSION:?set VERSION, for example VERSION=1.2.3}"
download_prefix="${DOWNLOAD_URL_PREFIX:-https://github.com/torjusb/Portside/releases/download/v$VERSION/}"
build="$root/build"
sparkle_bin="$root/.build/artifacts/sparkle/Sparkle/bin"

scripts/bundle.sh

stage="$build/dmg"
rm -rf "$stage" "$build/Portside.dmg"
mkdir -p "$stage"
ditto "$build/Portside.app" "$stage/Portside.app"
ln -s /Applications "$stage/Applications"
hdiutil create -volname Portside -srcfolder "$stage" -format UDZO "$build/Portside.dmg"
rm -rf "$stage"

# generate_appcast merges into any appcast already in its folder, so give it a fresh one.
feed="$build/feed"
rm -rf "$feed" "$build/appcast.xml"
mkdir -p "$feed"
cp "$build/Portside.dmg" "$feed/"
appcast_args=(--download-url-prefix "$download_prefix" "$feed")
if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
    printf '%s' "$SPARKLE_PRIVATE_KEY" | "$sparkle_bin/generate_appcast" --ed-key-file - "${appcast_args[@]}"
else
    "$sparkle_bin/generate_appcast" --account no.torjusb.portside "${appcast_args[@]}"
fi
mv "$feed/appcast.xml" "$build/appcast.xml"
rm -rf "$feed"

echo "$build/Portside.dmg"
echo "$build/appcast.xml"
