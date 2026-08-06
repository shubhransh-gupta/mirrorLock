import Cocoa
import SwiftUI
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    var toggleMenuItem: NSMenuItem?
    var unlockMenuItem: NSMenuItem?

    var mirrorOverlay: MirrorOverlay?
    var screenMirror: ScreenMirror?
    var inputGuard: InputGuard?
    var intruderAlert: IntruderAlert?
    var lockState: LockState!

    var preferencesWindow: NSWindow?
    var secondaryWindows: [NSWindow] = []
    var activationHotkey: GlobalHotkey?

    private var menuIsOpen = false
    private var isAuthenticating = false
    private var lockedAt: TimeInterval = 0
    private let gracePeriod: TimeInterval = 4.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupManagers()
        setupHotkeys()
        setupSleepHandlers()

        if !lockState.allPermissionsReady {
            showPreferences()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard mirrorOverlay == nil else { return false }
        showPreferences()
        return false
    }

    // MARK: - Setup

    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.image = NSImage(
            systemSymbolName: "lock.rectangle.on.rectangle",
            accessibilityDescription: "MirrorLock"
        )

        let menu = NSMenu()
        menu.delegate = self

        toggleMenuItem = NSMenuItem(
            title: "Activate Mirror Lock",
            action: #selector(toggleLock),
            keyEquivalent: "m"
        )
        toggleMenuItem?.keyEquivalentModifierMask = [.command, .shift]
        toggleMenuItem?.target = self
        menu.addItem(toggleMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Settings...", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        unlockMenuItem = NSMenuItem(
            title: "Unlock with Touch ID (⌘⇧U)...",
            action: #selector(unlockWithBiometrics),
            keyEquivalent: ""
        )
        unlockMenuItem?.target = self
        unlockMenuItem?.isEnabled = false
        menu.addItem(unlockMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarItem?.menu = menu
    }

    private func setupManagers() {
        inputGuard = InputGuard()
        intruderAlert = IntruderAlert()

        lockState = LockState()
        lockState.onToggle = { [weak self] in self?.toggleLock() }
        lockState.recheckPermissions()
    }

    private func setupHotkeys() {
        activationHotkey = GlobalHotkey(
            keyCode: UInt32(HotkeyCombo.activate.keyCode),
            modifiers: HotkeyCombo.activate.carbonModifiers
        ) { [weak self] in
            self?.toggleLock()
        }
    }

    private func setupSleepHandlers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(systemWillSleep),
                           name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(systemWillSleep),
                           name: NSWorkspace.screensDidSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(systemDidWake),
                           name: NSWorkspace.didWakeNotification, object: nil)
    }

    // MARK: - Lock Toggle

    @objc func toggleLock() {
        if mirrorOverlay != nil {
            deactivateLock()
        } else {
            activateLock()
        }
    }

    private func activateLock() {
        guard InputGuard.permissionsReady(), CGPreflightScreenCaptureAccess() else {
            showPermissionAlert()
            showPreferences()
            return
        }

        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? .zero

        let overlay = MirrorOverlay(
            screenFrame: frame,
            unlockHint: "Press ⌘⇧U to unlock"
        )
        mirrorOverlay = overlay

        toggleMenuItem?.title = "Deactivate Mirror Lock"
        toggleMenuItem?.keyEquivalent = ""
        unlockMenuItem?.isEnabled = true

        installSecondaryBlackouts(excluding: screen)

        let mirror = ScreenMirror(imageView: overlay.imageView)
        mirror.delegate = self
        screenMirror = mirror
        mirror.startCapture(excludingWindow: overlay.window)

        guard let guard_ = inputGuard else {
            deactivateLock()
            return
        }

        guard guard_.install(overlayWindow: overlay.window, unlock: HotkeyCombo.unlock) else {
            showInputLockFailedAlert()
            deactivateLock()
            return
        }

        guard_.onUnlockHotkey = { [weak self] in self?.unlockWithBiometrics() }
        guard_.onIntrusion = { [weak self] in
            guard let self, !self.isAuthenticating else { return }
            guard ProcessInfo.processInfo.systemUptime - self.lockedAt > self.gracePeriod else { return }
            self.mirrorOverlay?.flashOnIntrusion()
            self.intruderAlert?.trigger(on: screen)
        }

        lockedAt = ProcessInfo.processInfo.systemUptime
        lockState.isLocked = true
    }

    private func deactivateLock() {
        guard mirrorOverlay != nil else { return }

        inputGuard?.uninstall()
        screenMirror?.stopCapture()
        screenMirror = nil

        for w in secondaryWindows { w.close() }
        secondaryWindows.removeAll()

        mirrorOverlay?.window.close()
        mirrorOverlay = nil

        toggleMenuItem?.title = "Activate Mirror Lock"
        toggleMenuItem?.keyEquivalent = "m"
        toggleMenuItem?.keyEquivalentModifierMask = [.command, .shift]
        unlockMenuItem?.isEnabled = false
        lockState.isLocked = false
    }

    // MARK: - Secondary Displays

    private func installSecondaryBlackouts(excluding primary: NSScreen?) {
        let level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        for screen in NSScreen.screens where screen != primary {
            let w = NSWindow(contentRect: screen.frame, styleMask: [.borderless],
                             backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            w.level = level
            w.isOpaque = true
            w.backgroundColor = .black
            w.hasShadow = false
            w.ignoresMouseEvents = true
            w.makeKeyAndOrderFront(nil)
            inputGuard?.registerSecondaryOverlay(CGWindowID(w.windowNumber))
            secondaryWindows.append(w)
        }
    }

    // MARK: - Biometric Unlock

    @objc func unlockWithBiometrics() {
        guard mirrorOverlay != nil else { return }

        isAuthenticating = true
        mirrorOverlay?.window.level = .screenSaver
        for w in secondaryWindows { w.level = .screenSaver }

        Authenticator.shared.evaluateUnlock(reason: "Authenticate to deactivate MirrorLock.") { [weak self] success, _ in
            guard let self else { return }
            self.isAuthenticating = false
            if success, self.mirrorOverlay != nil {
                self.deactivateLock()
            } else if self.mirrorOverlay != nil {
                let shield = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
                self.mirrorOverlay?.window.level = shield
                for w in self.secondaryWindows { w.level = shield }
            }
        }
    }

    // MARK: - Sleep / Wake

    @objc private func systemWillSleep() {
        guard mirrorOverlay != nil else { return }
        deactivateLock()
    }

    @objc private func systemDidWake() {
        guard mirrorOverlay != nil, inputGuard?.isLocked != true else { return }
        deactivateLock()
    }

    // MARK: - Settings

    @objc func showPreferences() {
        lockState.recheckPermissions()

        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let root = SettingsView().environmentObject(lockState)
        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "MirrorLock Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 440))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Alerts

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = """
            MirrorLock needs Screen Recording, Accessibility, and Input Monitoring \
            permissions to lock your Mac while showing the live desktop.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            showPreferences()
        }
    }

    private func showInputLockFailedAlert() {
        let alert = NSAlert()
        alert.messageText = "Could Not Lock Input"
        alert.informativeText = """
            MirrorLock could not install the input lock. Check Accessibility and \
            Input Monitoring permissions in System Settings.
            """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Menu

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool { true }

    func menuWillOpen(_ menu: NSMenu) {
        menuIsOpen = true
        mirrorOverlay?.window.level = .popUpMenu
        for w in secondaryWindows { w.level = .popUpMenu }
    }

    func menuDidClose(_ menu: NSMenu) {
        menuIsOpen = false
        let shield = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        mirrorOverlay?.window.level = shield
        for w in secondaryWindows { w.level = shield }
    }

    @objc func quitApp() {
        deactivateLock()
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === preferencesWindow {
            preferencesWindow = nil
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if notification.object as? NSWindow === preferencesWindow {
            lockState.recheckPermissions()
        }
    }
}

extension AppDelegate: ScreenMirrorDelegate {
    func screenMirrorDidStop(_ mirror: ScreenMirror, error: Error?) {
        guard mirrorOverlay != nil, mirror === screenMirror else { return }
        deactivateLock()
        let alert = NSAlert()
        alert.messageText = "Mirror Lock Deactivated"
        alert.informativeText = """
            Screen capture stopped unexpectedly. This usually means Screen Recording \
            permission was revoked. Re-enable MirrorLock in System Settings.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
