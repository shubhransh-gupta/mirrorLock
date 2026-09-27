import SwiftUI
import Combine

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private enum Keys {
        static let keepMacAwake = "keepMacAwake"
        static let launchAtLogin = "launchAtLogin"
        static let autoLockIdleMinutes = "autoLockIdleMinutes"
        static let appleWatchTapUnlock = "appleWatchTapUnlock"
        static let blackoutSecondaryScreens = "blackoutSecondaryScreens"
        static let activateHotkey = "activateHotkey"
        static let unlockHotkey = "unlockHotkey"
        static let emergencyExitEnabled = "emergencyExitEnabled"
        static let emergencyExitHotkey = "emergencyExitHotkey"
    }

    @Published var keepMacAwake: Bool {
        didSet { UserDefaults.standard.set(keepMacAwake, forKey: Keys.keepMacAwake) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLoginManager.isEnabled = launchAtLogin
        }
    }

    @Published var autoLockIdleMinutes: Int {
        didSet { UserDefaults.standard.set(autoLockIdleMinutes, forKey: Keys.autoLockIdleMinutes) }
    }

    @Published var appleWatchTapUnlock: Bool {
        didSet { UserDefaults.standard.set(appleWatchTapUnlock, forKey: Keys.appleWatchTapUnlock) }
    }

    @Published var blackoutSecondaryScreens: Bool {
        didSet { UserDefaults.standard.set(blackoutSecondaryScreens, forKey: Keys.blackoutSecondaryScreens) }
    }

    @Published var emergencyExitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(emergencyExitEnabled, forKey: Keys.emergencyExitEnabled)
            onShortcutsChanged?()
        }
    }

    @Published var activateHotkey: HotkeyCombo {
        didSet {
            if let data = try? JSONEncoder().encode(activateHotkey) {
                UserDefaults.standard.set(data, forKey: Keys.activateHotkey)
            }
            onShortcutsChanged?()
        }
    }

    @Published var unlockHotkey: HotkeyCombo {
        didSet {
            if let data = try? JSONEncoder().encode(unlockHotkey) {
                UserDefaults.standard.set(data, forKey: Keys.unlockHotkey)
            }
            onShortcutsChanged?()
        }
    }

    @Published var emergencyExitHotkey: HotkeyCombo {
        didSet {
            if let data = try? JSONEncoder().encode(emergencyExitHotkey) {
                UserDefaults.standard.set(data, forKey: Keys.emergencyExitHotkey)
            }
            onShortcutsChanged?()
        }
    }

    var onShortcutsChanged: (() -> Void)?

    private init() {
        let defaults = UserDefaults.standard

        // Register defaults if first launch
        if defaults.object(forKey: Keys.keepMacAwake) == nil {
            defaults.set(true, forKey: Keys.keepMacAwake)
        }
        if defaults.object(forKey: Keys.blackoutSecondaryScreens) == nil {
            defaults.set(true, forKey: Keys.blackoutSecondaryScreens)
        }

        self.keepMacAwake = defaults.bool(forKey: Keys.keepMacAwake)
        self.launchAtLogin = LaunchAtLoginManager.isEnabled
        self.autoLockIdleMinutes = defaults.integer(forKey: Keys.autoLockIdleMinutes)
        self.appleWatchTapUnlock = defaults.bool(forKey: Keys.appleWatchTapUnlock)
        self.blackoutSecondaryScreens = defaults.bool(forKey: Keys.blackoutSecondaryScreens)
        self.emergencyExitEnabled = defaults.bool(forKey: Keys.emergencyExitEnabled)

        if let data = defaults.data(forKey: Keys.activateHotkey),
           let combo = try? JSONDecoder().decode(HotkeyCombo.self, from: data) {
            self.activateHotkey = combo
        } else {
            self.activateHotkey = HotkeyCombo.activate
        }

        if let data = defaults.data(forKey: Keys.unlockHotkey),
           let combo = try? JSONDecoder().decode(HotkeyCombo.self, from: data) {
            self.unlockHotkey = combo
        } else {
            self.unlockHotkey = HotkeyCombo.unlock
        }

        if let data = defaults.data(forKey: Keys.emergencyExitHotkey),
           let combo = try? JSONDecoder().decode(HotkeyCombo.self, from: data) {
            self.emergencyExitHotkey = combo
        } else {
            self.emergencyExitHotkey = HotkeyCombo.emergencyExitDefault
        }
    }
}
