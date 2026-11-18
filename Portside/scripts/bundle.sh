#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

version="${VERSION:-0.0.0}"
feed_url="${SU_FEED_URL:-https://github.com/torjusb/Portside/releases/latest/download/appcast.xml}"
if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "VERSION must be dotted numbers like 1.2.3, got '$version'" >&2
    exit 1
fi

build_args=(-c release --arch arm64 --arch x86_64)
swift build "${build_args[@]}"
products="$(swift build "${build_args[@]}" --show-bin-path)"

app="$root/build/Portside.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Frameworks" "$app/Contents/Resources"
cp "$products/Portside" "$app/Contents/MacOS/Portside"
ditto "$products/Sparkle.framework" "$app/Contents/Frameworks/Sparkle.framework"
cp "$root/Assets/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>no.torjusb.portside</string>
    <key>CFBundleName</key>
    <string>Portside</string>
    <key>CFBundleDisplayName</key>
    <string>Portside</string>
    <key>CFBundleExecutable</key>
    <string>Portside</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>SUFeedURL</key>
    <string>$feed_url</string>
    <key>SUPublicEDKey</key>
    <string>FLm5C4yu2kFSVcFfqwagkdvPEmOylcKmxq/9ZGC5Iow=</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
</dict>
</plist>
PLIST

# Sign nested code before the code that contains it, or the outer signature seals stale hashes.
sparkle="$app/Contents/Frameworks/Sparkle.framework"
codesign --force --sign - "$sparkle/Versions/Current/XPCServices/Installer.xpc"
codesign --force --sign - --preserve-metadata=entitlements "$sparkle/Versions/Current/XPCServices/Downloader.xpc"
codesign --force --sign - "$sparkle/Versions/Current/Autoupdate"
codesign --force --sign - "$sparkle/Versions/Current/Updater.app"
codesign --force --sign - "$sparkle"
codesign --force --sign - "$app"
codesign --verify --deep --strict --verbose=2 "$app"
echo "$app"
