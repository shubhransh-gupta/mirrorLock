import CoreGraphics
import ApplicationServices
import AppKit
import QuartzCore

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passRetained(event) }
    let guard_ = Unmanaged<InputGuard>.fromOpaque(refcon).takeUnretainedValue()
    return guard_.handleEvent(proxy: proxy, type: type, event: event)
}

final class InputGuard: NSObject {
    nonisolated(unsafe) private var tapRef: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?
    nonisolated(unsafe) private var lastIntrusionTime: CFTimeInterval = -.infinity
    nonisolated(unsafe) private var gestureMonitor: Any?

    nonisolated(unsafe) private var unlockKeyCode: Int64 = Int64(HotkeyCombo.unlock.keyCode)
    nonisolated(unsafe) private var unlockFlags: CGEventFlags = HotkeyCombo.unlock.cgEventFlags

    nonisolated(unsafe) private var overlayWindowID: CGWindowID = 0
    nonisolated(unsafe) private var appPID: pid_t = 0
    nonisolated(unsafe) private var secondaryOverlayIDs: Set<CGWindowID> = []
    nonisolated(unsafe) private var menuBarThreshold: CGFloat = 50

    nonisolated(unsafe) var onUnlockHotkey: (() -> Void)?
    nonisolated(unsafe) var onKeyboardIntrusion: (() -> Void)?
    nonisolated(unsafe) var onPointerIntrusion: (() -> Void)?

    static func accessibilityGranted() -> Bool { AXIsProcessTrusted() }
    static func inputMonitoringGranted() -> Bool { CGPreflightListenEventAccess() }
    static func permissionsReady() -> Bool { accessibilityGranted() && inputMonitoringGranted() }

    static func requestPermissions() {
        if !accessibilityGranted() {
            let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        }
        if !inputMonitoringGranted() {
            CGRequestListenEventAccess()
        }
    }

    var isLocked: Bool { tapRef != nil }

    @discardableResult
    func install(overlayWindow: NSWindow, unlock: HotkeyCombo) -> Bool {
        guard tapRef == nil else { return true }

        overlayWindowID = CGWindowID(overlayWindow.windowNumber)
        appPID = pid_t(ProcessInfo.processInfo.processIdentifier)
        menuBarThreshold = NSStatusBar.system.thickness + 8
        unlockKeyCode = Int64(unlock.keyCode)
        unlockFlags = unlock.cgEventFlags

        let kTabletPointer: UInt32 = 23
        let kTabletProximity: UInt32 = 24
        let kSystemDefined: UInt32 = 14
        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << kTabletPointer) |
            (1 << kTabletProximity) |
            (1 << kSystemDefined)

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: refcon
        ) else { return false }

        tapRef = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        let gestureMask: NSEvent.EventTypeMask = [
            .gesture, .magnify, .swipe, .rotate,
            .smartMagnify, .beginGesture, .endGesture, .directTouch
        ]
        gestureMonitor = NSEvent.addLocalMonitorForEvents(matching: gestureMask) { _ in nil }

        return true
    }

    func setUnlockCombo(_ combo: HotkeyCombo) {
        unlockKeyCode = Int64(combo.keyCode)
        unlockFlags = combo.cgEventFlags
    }

    func registerSecondaryOverlay(_ id: CGWindowID) {
        secondaryOverlayIDs.insert(id)
    }

    func uninstall() {
        if let tap = tapRef {
            CGEvent.tapEnable(tap: tap, enable: false)
            tapRef = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let monitor = gestureMonitor {
            NSEvent.removeMonitor(monitor)
            gestureMonitor = nil
        }
        secondaryOverlayIDs.removeAll()
    }

    nonisolated func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let loc = event.location

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = tapRef { CGEvent.tapEnable(tap: tap, enable: true) }
            return nil
        }

        if type == .keyDown {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            let masked = event.flags.intersection(HotkeyCombo.realModifierMask)
            if keycode == unlockKeyCode && masked == unlockFlags {
                if let cb = onUnlockHotkey {
                    Task { @MainActor in cb() }
                }
                return nil
            }
            fireKeyboardIntrusion()
            return nil
        }

        let isKeyboard = type == .keyUp || type == .flagsChanged
        if isKeyboard {
            fireKeyboardIntrusion()
            return nil
        }

        let kSystemDefined: UInt32 = 14
        if type.rawValue == kSystemDefined {
            fireKeyboardIntrusion()
            return nil
        }

        let isMouse = type == .leftMouseDown || type == .leftMouseUp ||
                      type == .rightMouseDown || type == .rightMouseUp ||
                      type == .scrollWheel
        let isMove = type == .mouseMoved || type == .leftMouseDragged ||
                     type == .rightMouseDragged || type == .otherMouseDragged

        if isMove && loc.y < menuBarThreshold {
            return Unmanaged.passRetained(event)
        }

        if isMouse && pointHitsWhitelistedWindow(loc) {
            return Unmanaged.passRetained(event)
        }

        let now = CACurrentMediaTime()
        if now - lastIntrusionTime > 0.5 {
            lastIntrusionTime = now
            if let cb = onPointerIntrusion {
                Task { @MainActor in cb() }
            }
        }

        return nil
    }

    nonisolated private func fireKeyboardIntrusion() {
        let now = CACurrentMediaTime()
        if now - lastIntrusionTime > 0.5 {
            lastIntrusionTime = now
            if let cb = onKeyboardIntrusion {
                Task { @MainActor in cb() }
            }
        }
    }

    nonisolated private func pointHitsWhitelistedWindow(_ loc: CGPoint) -> Bool {
        let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        for info in windowList {
            guard
                let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                let pid = info[kCGWindowOwnerPID as String] as? Int32,
                let wid = info[kCGWindowNumber as String] as? CGWindowID
            else { continue }

            let rect = CGRect(
                x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0, height: bounds["Height"] ?? 0
            )
            guard rect.contains(loc) else { continue }

            if pid == appPID {
                if wid == overlayWindowID || secondaryOverlayIDs.contains(wid) {
                    continue
                }
                return true
            } else {
                return false
            }
        }
        return false
    }
}
