#!/usr/bin/env bash
set -euo pipefail

REPO="${MIRRORLOCK_REPO:-shubhransh-gupta/mirrorLock}"
APP_NAME="MirrorLock"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

echo "=================================================="
echo "          MirrorLock Installer for macOS          "
echo "=================================================="

# Check if user prefers Homebrew
if command -v brew >/dev/null 2>&1; then
  echo "💡 Tip: You have Homebrew installed! You can also install with:"
  echo "   brew tap shubhransh-gupta/tap"
  echo "   brew install --cask mirrorlock"
  echo ""
fi

echo "→ Fetching latest MirrorLock release..."
JSON="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"
VERSION="$(echo "$JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')"

PKG_URL="$(echo "$JSON" | grep '"browser_download_url".*\.pkg"' | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/' || true)"
ZIP_URL="$(echo "$JSON" | grep '"browser_download_url".*\.zip"' | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/' || true)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if pgrep -xq "$APP_NAME" 2>/dev/null; then
  echo "→ Quitting running ${APP_NAME}..."
  osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 1
fi

if [[ -n "$PKG_URL" && "$PKG_URL" != "$JSON" ]]; then
  echo "→ Downloading PKG installer for ${VERSION}..."
  curl -fsSL "$PKG_URL" -o "$TMP/MirrorLock.pkg"
  echo "→ Installing via macOS installer..."
  sudo installer -pkg "$TMP/MirrorLock.pkg" -target /
elif [[ -n "$ZIP_URL" && "$ZIP_URL" != "$JSON" ]]; then
  echo "→ Downloading ZIP for ${VERSION}..."
  curl -fsSL "$ZIP_URL" -o "$TMP/MirrorLock.zip"
  unzip -q "$TMP/MirrorLock.zip" -d "$TMP"
  if [[ ! -d "$TMP/${APP_NAME}.app" ]]; then
    echo "Downloaded archive does not contain ${APP_NAME}.app" >&2
    exit 1
  fi
  echo "→ Installing to ${INSTALL_DIR}..."
  rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
  mv "$TMP/${APP_NAME}.app" "${INSTALL_DIR}/"
  xattr -dr com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true
else
  echo "No release asset found. Check https://github.com/${REPO}/releases" >&2
  exit 1
fi

echo "✓ MirrorLock ${VERSION} installed successfully."
echo "  Launch from Applications or run: open -a ${APP_NAME}"
open -a "$APP_NAME" 2>/dev/null || true
