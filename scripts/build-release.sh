#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  for xc in /Applications/Xcode_16*.app /Applications/Xcode_17*.app /Applications/Xcode.app; do
    if [[ -d "$xc/Contents/Developer" ]]; then
      export DEVELOPER_DIR="$xc/Contents/Developer"
      break
    fi
  done
fi

XCODEBUILD="${DEVELOPER_DIR:+$DEVELOPER_DIR/usr/bin/}xcodebuild"
if [[ ! -x "$XCODEBUILD" ]]; then
  XCODEBUILD="xcodebuild"
fi

VERSION="${1:-$(grep MARKETING_VERSION MirrorLock.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/')}"
DERIVED="$ROOT/build/DerivedData"
PRODUCTS="$DERIVED/Build/Products/Release"
APP="$PRODUCTS/MirrorLock.app"
ZIP="$ROOT/MirrorLock-${VERSION}.zip"
PKG="$ROOT/MirrorLock-${VERSION}.pkg"
CASK_DIR="$ROOT/Casks"
CASK_FILE="$CASK_DIR/mirrorlock.rb"

echo "==========================================="
echo "Building MirrorLock ${VERSION}..."
echo "==========================================="

rm -rf "$ROOT/build"
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

echo "→ Packaging ZIP archive..."
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
ZIP_SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "✓ Created $ZIP ($(du -h "$ZIP" | cut -f1)) [SHA256: $ZIP_SHA256]"

echo "→ Packaging PKG installer for Homebrew & direct installation..."
rm -f "$PKG"
pkgbuild \
  --component "$APP" \
  --identifier "com.shubhranshgupta.mirrorlock" \
  --version "${VERSION}" \
  --install-location "/Applications" \
  "$PKG"
PKG_SHA256="$(shasum -a 256 "$PKG" | awk '{print $1}')"
echo "✓ Created $PKG ($(du -h "$PKG" | cut -f1)) [SHA256: $PKG_SHA256]"

mkdir -p "$CASK_DIR"
cat > "$CASK_FILE" <<EOF
cask "mirrorlock" do
  version "${VERSION}"
  sha256 "${PKG_SHA256}"

  url "https://github.com/shubhransh-gupta/mirrorLock/releases/download/v#{version}/MirrorLock-#{version}.pkg"
  name "MirrorLock"
  desc "Lock keyboard & mouse behind a live desktop mirror for AI botsitting"
  homepage "https://github.com/shubhransh-gupta/mirrorLock"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  pkg "MirrorLock-#{version}.pkg"

  uninstall pkgutil: "com.shubhranshgupta.mirrorlock",
            quit:    "com.shubhranshgupta.mirrorlock"

  zap trash: [
    "~/Library/Application Support/com.shubhranshgupta.mirrorlock",
    "~/Library/Caches/com.shubhranshgupta.mirrorlock",
    "~/Library/Containers/com.shubhranshgupta.mirrorlock",
    "~/Library/Preferences/com.shubhranshgupta.mirrorlock.plist",
  ]
end
EOF

echo "✓ Generated Homebrew Cask formula at $CASK_FILE"
echo ""
echo "Installation commands:"
echo "  brew tap shubhransh-gupta/tap"
echo "  brew install --cask mirrorlock"
echo "or directly:"
echo "  brew install --cask shubhransh-gupta/tap/mirrorlock"
echo "==========================================="
