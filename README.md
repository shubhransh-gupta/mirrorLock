# MirrorLock

**Watch your AI work. Touch nothing.**

[![Release](https://img.shields.io/github/v/release/shubhransh-gupta/mirrorLock?style=flat-square&label=download)](https://github.com/shubhransh-gupta/mirrorLock/releases/latest)
[![Homebrew](https://img.shields.io/badge/homebrew-cask-orange?style=flat-square)](https://github.com/shubhransh-gupta/homebrew-tap)
[![Platform](https://img.shields.io/badge/platform-macOS%20Sonoma%2014+-lightgrey.svg?style=flat-square)](https://github.com/shubhransh-gupta/mirrorLock)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

🌐 **Website:** [shubhransh-gupta.github.io/mirrorLock](https://shubhransh-gupta.github.io/mirrorLock)

MirrorLock is a native macOS menu bar app for **botsitting** — leaving your AI coding agents (Claude Code, Cursor, Copilot, Codex, etc.) running while you step away. It mirrors your live desktop behind a subtle dimmed overlay and hard-locks keyboard, mouse, and trackpad at the macOS event-tap level. The screen stays fully visible so anyone in the room can watch the agent work, but nothing can be touched. Unlock instantly with Touch ID, Apple Watch, or Android Watch.

Inspired by [Wardlume](https://github.com/arpitagarwal1301/wardlume-screen-lock), built from scratch with an open MIT license and broad macOS compatibility (Sonoma 14+).

---

## ⚡ Quick Install

### Homebrew (Recommended)

Install directly from the official tap:

```bash
brew tap shubhransh-gupta/tap
brew install --cask mirrorlock
```

Or install in a single command:

```bash
brew install --cask shubhransh-gupta/tap/mirrorlock
```

*Installs cleanly via signed `.pkg` installer directly into `/Applications` without Gatekeeper "damaged" warnings or quarantine workarounds.*

### One-line curl installer

```bash
curl -fsSL https://raw.githubusercontent.com/shubhransh-gupta/mirrorLock/main/scripts/install.sh | bash
```

Or download the installer (`.pkg`) or `.zip` directly from [Releases](https://github.com/shubhransh-gupta/mirrorLock/releases/latest).

---

## ✨ Features

- 🖥️ **Live Mirror Overlay** — Your desktop stays visible behind a subtle dimmed layer via ScreenCaptureKit.
- 🔒 **Hard Input Lock** — Hard-blocks keyboard, mouse, trackpad, scrolling, gestures, and media keys via low-level `CGEventTap`.
- ⌚ **Apple Watch & Android Watch Unlock** — Rest your finger on Touch ID or use your Apple Watch or Android Watch to unlock. Includes optional "Tap to unlock" with compatible watches.
- ☕ **Keeps Your Mac Awake** — Holds an IOKit power assertion while locked so the display and system never idle-sleep. Your AI agents keep coding without interruption.
- ⏱️ **Auto-Lock When Idle** — Automatically locks after 1–30 minutes of inactivity, preceded by an interactive 10-second cancelable countdown HUD.
- 🚀 **Launch at Login** — Starts quietly in your menu bar on system startup via `SMAppService`.
- ⌨️ **Configurable Hotkeys** — Customize activation shortcut (⌘⇧M default, or ⌘⇧L Wardlume style) and unlock shortcut (⌘⇧U).
- 🛑 **Emergency Exit Hotkey** — Optional unauthenticated escape key (e.g. ⌃⌥⌘Esc) for guaranteed safety.
- 🖥️ **Multi-Display Aware** — Primary display shows live mirror; secondary displays are shielded in black. Unplugging or plugging monitors never unlocks your Mac.
- 🚨 **Intruder Alerts & Watching Eye** — Typing triggers a watching eye icon, and trackpad/mouse touches trigger a red border flash and alert sound.
- 🛡️ **100% Local & Private** — MIT licensed, zero telemetry, zero analytics, zero network requests.

---

## 📱 Watch Unlock Details

### Apple Watch Unlock
- Double-press the side button on your Apple Watch while MirrorLock is active
- Optional "Tap to unlock" feature allows unlocking by tapping your Apple Watch screen
- Uses secure local authentication via Apple's frameworks

### Android Watch Unlock (Framework Ready)
- Pair with compatible Android Wear OS companion app (available separately)
- Send unlock signals from your watch to mirrorLock via secure local connection
- Same tap-to-unlock convenience as Apple Watch
- Requires Android companion app for full functionality (framework included in this version)

---

## 🔒 Security & Privacy
- All processing happens locally on your Mac
- No data leaves your device
- No internet connection required for core functionality
- Open source MIT license - audit the code yourself

---

## 👥 Who Uses MirrorLock?
- AI developers leaving coding agents running overnight
- Presenters who need to step away during demonstrations
- Anyone wanting to secure their Mac while keeping the screen visible
- Parents, teachers, and professionals in shared spaces

---

## 📄 License
MirrorLock is released under the MIT License. See [LICENSE](LICENSE) for details.

🌐 **Website:** [shubhransh-gupta.github.io/mirrorLock](https://shubhransh-gupta.github.io/mirrorLock)
📦 **Download:** [GitHub Releases](https://github.com/shubhransh-gupta/mirrorLock/releases/latest)
