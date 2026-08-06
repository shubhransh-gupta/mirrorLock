# MirrorLock

**Watch your AI work. Touch nothing.**

MirrorLock is a macOS menu bar app for **botsitting** — leave your AI coding agents (Cursor, Claude Code, Copilot, etc.) running while you step away. It mirrors your live desktop behind a dimmed overlay and hard-locks keyboard, mouse, and trackpad at the macOS event-tap level. The screen stays fully visible so anyone can watch the agent work, but nothing can be touched. Unlock instantly with Touch ID.

Inspired by the concept of [Wardlume](https://github.com/arpitagarwal1301/wardlume), rebuilt from scratch with a simpler architecture and MIT license.

## Features

- **Live mirror overlay** — your desktop stays visible behind a subtle dimmed layer via ScreenCaptureKit
- **Hard input lock** — keyboard, mouse, trackpad, scroll, and media keys blocked via CGEventTap
- **Touch ID unlock** — rest your finger or use your password to unlock
- **Intruder alerts** — wrong touches trigger a red border flash and alert sound
- **Multi-display aware** — secondary screens are blacked out while locked
- **Global hotkeys** — activate and unlock from anywhere, even while focused in your IDE
- **Local-only** — no network, no analytics, no accounts

## How MirrorLock differs

| | Wardlume | MirrorLock |
|---|---|---|
| Visual | Metal glass-shield shader | Live desktop mirror + dim overlay |
| Hotkey | ⌘⇧L | ⌘⇧M |
| Reactions | Character packs with images/sounds | Border flash + system sound |
| Onboarding | PermissionPilot SDK | Built-in settings panel |
| License | PolyForm Noncommercial | MIT |
| Min macOS | Tahoe 26+ | Sonoma 14+ |

## Usage

1. Launch MirrorLock — it lives in your menu bar.
2. Press **⌘⇧M** from anywhere to **activate the mirror lock**.
3. Walk away. The screen stays visible; input is locked.
4. Return and **rest your finger on Touch ID** — or press **⌘⇧U** — to unlock.

## Permissions

MirrorLock needs three permissions, used only while the lock is active:

| Permission | Why |
|---|---|
| **Screen Recording** | Mirrors your live desktop behind the overlay |
| **Accessibility** | Locks keyboard, mouse, and trackpad |
| **Input Monitoring** | Detects intrusion attempts |

Grant them in **Settings → Permissions** inside the app, or via System Settings → Privacy & Security.

## Build from source

Requires **Xcode 16+** on **macOS 14+**.

```bash
git clone https://github.com/shubhransh-gupta/mirrorLock.git
cd mirrorLock
open MirrorLock.xcodeproj
```

Select the **MirrorLock** scheme and press **⌘R**.

Built with Swift, SwiftUI, AppKit, and ScreenCaptureKit.

## License

[MIT](LICENSE) — use it however you like.
