# MirrorLock

**Watch your AI work. Touch nothing.**

[![Release](https://img.shields.io/github/v/release/shubhransh-gupta/mirrorLock?style=flat-square&label=download)](https://github.com/shubhransh-gupta/mirrorLock/releases/latest)
[![Homebrew](https://img.shields.io/badge/homebrew-cask-orange?style=flat-square)](https://github.com/shubhransh-gupta/homebrew-tap)
[![Platform](https://img.shields.io/badge/platform-macOS%20Sonoma%2014+-lightgrey.svg?style=flat-square)](https://github.com/shubhransh-gupta/mirrorLock)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

🌐 **Website:** [shubhransh-gupta.github.io/mirrorLock](https://shubhransh-gupta.github.io/mirrorLock)

MirrorLock is a native macOS menu bar app for **botsitting** — leaving your AI coding agents (Claude Code, Cursor, Copilot, Codex, etc.) running while you step away. It mirrors your live desktop behind a subtle dimmed overlay and hard-locks keyboard, mouse, and trackpad at the macOS event-tap level. The screen stays fully visible so anyone in the room can watch the agent work, but nothing can be touched. Unlock instantly with Touch ID or Apple Watch.

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
- ⌚ **Apple Watch & Touch ID Unlock** — Rest your finger on Touch ID or double-press your Apple Watch side button. Includes optional "Tap to unlock with Apple Watch".
- ☕ **Keeps Your Mac Awake** — Holds an IOKit power assertion while locked so the display and system never idle-sleep. Your AI agents keep coding without interruption.
- ⏱️ **Auto-Lock When Idle** — Automatically locks after 1–30 minutes of inactivity, preceded by an interactive 10-second cancelable countdown HUD.
- 🚀 **Launch at Login** — Starts quietly in your menu bar on system startup via `SMAppService`.
- ⌨️ **Configurable Hotkeys** — Customize activation shortcut (⌘⇧M default, or ⌘⇧L Wardlume style) and unlock shortcut (⌘⇧U).
- 🛑 **Emergency Exit Hotkey** — Optional unauthenticated escape key (e.g. ⌃⌥⌘Esc) for guaranteed safety.
- 🖥️ **Multi-Display Aware** — Primary display shows live mirror; secondary displays are shielded in black. Unplugging or plugging monitors never unlocks your Mac.
- 🚨 **Intruder Alerts & Watching Eye** — Typing triggers a watching eye icon, and trackpad/mouse touches trigger a red border flash and alert sound.
- 🛡️ **100% Local & Private** — MIT licensed, zero telemetry, zero analytics, zero network requests.

---

## ⚖️ How MirrorLock Compares to Wardlume

| Feature | Wardlume | MirrorLock |
|---|---|---|
| **License** | PolyForm Noncommercial (commercial use restricted) | **MIT** (100% free for personal & commercial use) |
| **macOS Support** | Tahoe 26+ on Apple Silicon only | **Sonoma 14+** (Apple Silicon & Intel) |
| **Homebrew Install** | `brew install --cask wardlume` | `brew install --cask mirrorlock` |
| **Visual Style** | Metal glass-shield shader | High-performance desktop mirror + dim overlay |
| **Unlock Methods** | Touch ID, Apple Watch, Password | **Touch ID, Apple Watch, Password** |
| **Keep Awake** | Yes (power assertion) | **Yes (IOKit power assertion)** |
| **Auto-Lock Idle** | Yes (with 10s countdown) | **Yes (with 10s cancelable HUD)** |
| **Launch at Login** | Yes | **Yes (`SMAppService`)** |
| **Emergency Exit** | Yes | **Yes (configurable)** |
| **Screen Reconnect Safe**| Yes | **Yes (`didChangeScreenParameters`)** |

---

## 🚀 Usage

1. **Launch MirrorLock** — it lives quietly in your menu bar.
2. Press **⌘⇧M** from anywhere (even while inside your IDE) to **activate mirror lock**.
3. **Walk away.** Your AI agents (Claude Code, Cursor, Copilot, etc.) continue running on screen; input is completely locked.
4. **Return and unlock.** Rest your finger on **Touch ID**, double-press your **Apple Watch**, or press **⌘⇧U**.

---

## 🔐 Permissions

MirrorLock requires three macOS permissions, active only while locked:

| Permission | Why |
|---|---|
| **Screen Recording** | Captures and renders the live desktop behind the lock overlay |
| **Accessibility** | Blocks keyboard, mouse, and trackpad input via `CGEventTap` |
| **Input Monitoring** | Listens for global hotkeys and intruder attempts |

Permissions can be granted during the first launch onboarding wizard, inside **MirrorLock Settings → Permissions**, or via **System Settings → Privacy & Security**.

---

## 🛠️ Build from Source

Requires **Xcode 16+** on **macOS 14+**.

```bash
git clone https://github.com/shubhransh-gupta/mirrorLock.git
cd mirrorLock
open MirrorLock.xcodeproj
```

Select the **MirrorLock** scheme and press **⌘R**.

To build release packages and Homebrew Cask formula locally:

```bash
./scripts/build-release.sh 1.1.0
```

---

## 📄 License

[MIT License](LICENSE) — Feel free to use, modify, and distribute for any purpose.
