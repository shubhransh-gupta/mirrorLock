#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

XCODEBUILD="${DEVELOPER_DIR:+$DEVELOPER_DIR/usr/bin/}xcodebuild"
if [[ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
  XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
fi

VERSION="${1:-$(grep MARKETING_VERSION MirrorLock.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/')}"
DERIVED="$ROOT/build/DerivedData"
PRODUCTS="$DERIVED/Build/Products/Release"
APP="$PRODUCTS/MirrorLock.app"
ZIP="MirrorLock-${VERSION}.zip"

echo "Building MirrorLock ${VERSION}…"

"$XCODEBUILD" \
  -project MirrorLock.xcodeproj \
  -scheme MirrorLock \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build

if [[ ! -d "$APP" ]]; then
  echo "Build failed — $APP not found" >&2
  exit 1
fi

rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "✓ Created $ZIP ($(du -h "$ZIP" | cut -f1))"
