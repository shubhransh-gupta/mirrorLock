import Cocoa
import SwiftUI
import CoreGraphics

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    var toggleMenuItem: NSMenuItem?
    var unlockMenuItem: NSMenuItem?
    var autoLockStatusMenuItem: NSMenuItem?
    var keepAwakeMenuItem: NSMenuItem?

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
        setupManagers()
        setupMenuBar()
        setupHotkeys()
        setupSleepAndDisplayHandlers()
        setupIdleMonitoring()

        if !lockState.allPermissionsReady {
            showPreferences()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        deactivateLock()
        IdleLockManager.shared.stopMonitoring()
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

        let activateCombo = Preferences.shared.activateHotkey
        toggleMenuItem = NSMenuItem(
            title: "Activate Mirror Lock (\(activateCombo.displayString))",
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        toggleMenuItem?.target = self
        menu.addItem(toggleMenuItem!)

        let unlockCombo = Preferences.shared.unlockHotkey
        unlockMenuItem = NSMenuItem(
            title: "Unlock with Touch ID / Apple Watch (\(unlockCombo.displayString))...",
            action: #selector(unlockWithBiometrics),
            keyEquivalent: ""
        )
        unlockMenuItem?.target = self
        unlockMenuItem?.isEnabled = false
        menu.addItem(unlockMenuItem!)

        menu.addItem(NSMenuItem.separator())

        autoLockStatusMenuItem = NSMenuItem(
            title: autoLockMenuTitle(),
            action: #selector(toggleAutoLockQuick),
            keyEquivalent: ""
        )
        autoLockStatusMenuItem?.target = self
        menu.addItem(autoLockStatusMenuItem!)

        keepAwakeMenuItem = NSMenuItem(
            title: "Keep Mac Awake: \(Preferences.shared.keepMacAwake ? "On" : "Off")",
            action: #selector(toggleKeepAwakeQuick),
            keyEquivalent: ""
        )
        keepAwakeMenuItem?.target = self
        menu.addItem(keepAwakeMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Settings...", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let updatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updatesItem.target = self
        menu.addItem(updatesItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MirrorLock", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarItem?.menu = menu
    }

    private func autoLockMenuTitle() -> String {
        let mins = Preferences.shared.autoLockIdleMinutes
        return mins > 0 ? "Auto-Lock: \(mins)m idle" : "Auto-Lock: Off"
    }

    @objc private func toggleAutoLockQuick() {
        let current = Preferences.shared.autoLockIdleMinutes
        if current == 0 {
            Preferences.shared.autoLockIdleMinutes = 5
        } else if current == 5 {
            Preferences.shared.autoLockIdleMinutes = 10
        } else {
            Preferences.shared.autoLockIdleMinutes = 0
        }
        autoLockStatusMenuItem?.title = autoLockMenuTitle()
    }

    @objc private func toggleKeepAwakeQuick() {
        Preferences.shared.keepMacAwake.toggle()
        keepAwakeMenuItem?.title = "Keep Mac Awake: \(Preferences.shared.keepMacAwake ? "On" : "Off")"
        if mirrorOverlay != nil {
            if Preferences.shared.keepMacAwake {
                PowerManager.shared.preventSleep()
            } else {
                PowerManager.shared.allowSleep()
            }
        }
    }

    @objc private func checkForUpdates() {
        if let url = URL(string: "https://github.com/shubhransh-gupta/mirrorLock/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }

    private func setupManagers() {
        inputGuard = InputGuard()
        intruderAlert = IntruderAlert()

        lockState = LockState()
        lockState.onToggle = { [weak self] in self?.toggleLock() }
        lockState.recheckPermissions()

        Preferences.shared.onShortcutsChanged = { [weak self] in
            Task { @MainActor [weak self] in
                self?.setupHotkeys()
                self?.updateMenuTitles()
            }
        }
    }

    private func updateMenuTitles() {
        let activateCombo = Preferences.shared.activateHotkey
        let unlockCombo = Preferences.shared.unlockHotkey
        if mirrorOverlay != nil {
            toggleMenuItem?.title = "Deactivate Mirror Lock"
        } else {
            toggleMenuItem?.title = "Activate Mirror Lock (\(activateCombo.displayString))"
        }
        unlockMenuItem?.title = "Unlock with Touch ID / Apple Watch (\(unlockCombo.displayString))..."
        autoLockStatusMenuItem?.title = autoLockMenuTitle()
        keepAwakeMenuItem?.title = "Keep Mac Awake: \(Preferences.shared.keepMacAwake ? "On" : "Off")"
    }

    private func setupHotkeys() {
        activationHotkey = nil
        let combo = Preferences.shared.activateHotkey
        activationHotkey = GlobalHotkey(
            keyCode: UInt32(combo.keyCode),
            modifiers: combo.carbonModifiers
        ) { [weak self] in
            self?.toggleLock()
        }

        if let guard_ = inputGuard {
            guard_.setUnlockCombo(Preferences.shared.unlockHotkey)
            guard_.setEmergencyExit(
                enabled: Preferences.shared.emergencyExitEnabled,
                combo: Preferences.shared.emergencyExitHotkey
            )
            guard_.setAppleWatchTapUnlock(enabled: Preferences.shared.appleWatchTapUnlock)
        }
    }

    private func setupSleepAndDisplayHandlers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(systemWillSleep),
                           name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(systemWillSleep),
                           name: NSWorkspace.screensDidSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(systemDidWake),
                           name: NSWorkspace.didWakeNotification, object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupIdleMonitoring() {
        IdleLockManager.shared.isLockActive = { [weak self] in
            self?.mirrorOverlay != nil
        }
        IdleLockManager.shared.onAutoLockTriggered = { [weak self] in
            guard let self, self.mirrorOverlay == nil else { return }
            self.activateLock()
        }
        IdleLockManager.shared.startMonitoring()
    }

    // MARK: - Lock Toggle

    @objc func toggleLock() {
        if mirrorOverlay != nil {
            deactivateLock()
        } else {
            activateLock()
        }
    }

    func activateLock() {
        guard InputGuard.permissionsReady(), CGPreflightScreenCaptureAccess() else {
            showPermissionAlert()
            showPreferences()
            return
        }

        IdleLockManager.shared.dismissCountdown()

        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? .zero

        let overlay = MirrorOverlay(screenFrame: frame)
        mirrorOverlay = overlay

        updateMenuTitles()
        unlockMenuItem?.isEnabled = true

        if Preferences.shared.blackoutSecondaryScreens {
            installSecondaryBlackouts(excluding: screen)
        }

        let mirror = ScreenMirror(imageView: overlay.imageView)
        mirror.delegate = self
        screenMirror = mirror
        mirror.startCapture(excludingWindow: overlay.window)

        guard let guard_ = inputGuard else {
            deactivateLock()
            return
        }

        let emergency = (
            enabled: Preferences.shared.emergencyExitEnabled,
            combo: Preferences.shared.emergencyExitHotkey
        )
        guard guard_.install(
            overlayWindow: overlay.window,
            unlock: Preferences.shared.unlockHotkey,
            emergencyExit: emergency,
            watchTapUnlock: Preferences.shared.appleWatchTapUnlock
        ) else {
            showInputLockFailedAlert()
            deactivateLock()
            return
        }

        guard_.onUnlockHotkey = { [weak self] in self?.unlockWithBiometrics() }
        guard_.onEmergencyExit = { [weak self] in self?.deactivateLock() }
        guard_.onKeyboardIntrusion = { [weak self] in
            guard let self, !self.isAuthenticating else { return }
            guard ProcessInfo.processInfo.systemUptime - self.lockedAt > self.gracePeriod else { return }
            self.mirrorOverlay?.showEyeOnKeyboardIntrusion()
        }
        guard_.onPointerIntrusion = { [weak self] in
            guard let self, !self.isAuthenticating else { return }
            guard ProcessInfo.processInfo.systemUptime - self.lockedAt > self.gracePeriod else { return }
            self.intruderAlert?.trigger(on: screen)
        }

        if Preferences.shared.keepMacAwake {
            PowerManager.shared.preventSleep()
        }

        lockedAt = ProcessInfo.processInfo.systemUptime
        lockState.isLocked = true
    }

    func deactivateLock() {
        guard mirrorOverlay != nil else { return }

        PowerManager.shared.allowSleep()
        inputGuard?.uninstall()
        screenMirror?.stopCapture()
        screenMirror = nil

        for w in secondaryWindows { w.close() }
        secondaryWindows.removeAll()

        mirrorOverlay?.window.close()
        mirrorOverlay = nil

        updateMenuTitles()
        unlockMenuItem?.isEnabled = false
        lockState.isLocked = false
    }

    // MARK: - Secondary Displays & Screen Changes

    private func installSecondaryBlackouts(excluding primary: NSScreen?) {
        for w in secondaryWindows { w.close() }
        secondaryWindows.removeAll()
        inputGuard?.clearSecondaryOverlays()

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

    @objc private func displayParametersDidChange() {
        guard mirrorOverlay != nil else { return }
        // Keep lock active and re-adapt to new screen geometry
        let primary = NSScreen.main ?? NSScreen.screens.first
        if let primary {
            mirrorOverlay?.window.setFrame(primary.frame, display: true)
        }
        if Preferences.shared.blackoutSecondaryScreens {
            installSecondaryBlackouts(excluding: primary)
        }
    }

    // MARK: - Biometric Unlock (Touch ID, Apple Watch, Password)

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

        let root = SettingsView()
            .environmentObject(lockState)
            .environmentObject(Preferences.shared)

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "MirrorLock Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 600, height: 480))
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
        updateMenuTitles()
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
