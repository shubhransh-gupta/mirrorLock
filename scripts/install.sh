#!/usr/bin/env bash
set -euo pipefail

REPO="${MIRRORLOCK_REPO:-shubhransh-gupta/mirrorLock}"
APP_NAME="MirrorLock"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

echo "→ Fetching latest MirrorLock release…"

JSON="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"
VERSION="$(echo "$JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')"
URL="$(echo "$JSON" | grep '"browser_download_url".*\.zip"' | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')"

if [[ -z "$URL" || "$URL" == "$JSON" ]]; then
  echo "No release zip found. Check https://github.com/${REPO}/releases" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Downloading ${VERSION}…"
curl -fsSL "$URL" -o "$TMP/MirrorLock.zip"
unzip -q "$TMP/MirrorLock.zip" -d "$TMP"

if [[ ! -d "$TMP/${APP_NAME}.app" ]]; then
  echo "Downloaded archive does not contain ${APP_NAME}.app" >&2
  exit 1
fi

if pgrep -xq "$APP_NAME" 2>/dev/null; then
  echo "→ Quitting running ${APP_NAME}…"
  osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 1
fi

echo "→ Installing to ${INSTALL_DIR}…"
rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
mv "$TMP/${APP_NAME}.app" "${INSTALL_DIR}/"
xattr -dr com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo "✓ MirrorLock ${VERSION} installed."
echo "  Launch from Applications or run: open -a ${APP_NAME}"
open -a "$APP_NAME" 2>/dev/null || true
