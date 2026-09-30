import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var lockState: LockState
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        TabView {
            OverviewTab()
                .tabItem { Label("Overview", systemImage: "info.circle") }

            LockAndUnlockTab()
                .tabItem { Label("Lock & Unlock", systemImage: "lock.shield") }

            AutomationTab()
                .tabItem { Label("Automation", systemImage: "bolt.circle") }

            DisplaysTab()
                .tabItem { Label("Displays & Safety", systemImage: "display.2") }

            PermissionsTab()
                .tabItem { Label("Permissions", systemImage: "hand.raised") }
        }
        .frame(minWidth: 580, minHeight: 460)
        .onAppear { lockState.recheckPermissions() }
    }
}

// MARK: - Overview Tab

private struct OverviewTab: View {
    @EnvironmentObject var lockState: LockState
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: "lock.rectangle.on.rectangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("MirrorLock")
                            .font(.title2.bold())
                        Text("Watch your AI work. Touch nothing.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(lockState.isLocked ? "Deactivate Lock" : "Activate Lock") {
                        lockState.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(lockState.isLocked ? .red : .blue)
                }

                Divider()

                HStack(spacing: 10) {
                    StatusBadge(label: "Lock", active: lockState.isLocked,
                                activeText: "Active", inactiveText: "Inactive")
                    StatusBadge(label: "Permissions", active: lockState.allPermissionsReady,
                                activeText: "Ready", inactiveText: "Missing")
                    StatusBadge(label: "Keep Awake", active: preferences.keepMacAwake,
                                activeText: "On", inactiveText: "Off")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("How MirrorLock Works")
                        .font(.headline)

                    StepRow(
                        number: "1",
                        title: "Lock Your Mac (\(preferences.activateHotkey.displayString))",
                        desc: "Press your global shortcut or use the menu bar icon. Input is immediately hard-locked at the event-tap level."
                    )
                    StepRow(
                        number: "2",
                        title: "Step Away & Botsit Agents",
                        desc: "Your desktop remains 100% visible behind a subtle dimmed overlay. Claude Code, Cursor, Copilot, or long builds continue uninterrupted."
                    )
                    StepRow(
                        number: "3",
                        title: "Unlock Instantly (\(preferences.unlockHotkey.displayString))",
                        desc: "Return to your desk and rest your finger on Touch ID or double-press your Apple Watch."
                    )
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                HStack {
                    Text("Tip: Install directly via Homebrew with ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("brew install --cask shubhransh-gupta/tap/mirrorlock")
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                }
            }
            .padding(22)
        }
    }
}

// MARK: - Lock & Unlock Tab

private struct LockAndUnlockTab: View {
    @EnvironmentObject var preferences: Preferences
    @State private var testAuthResult: String?
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Biometrics & Apple Watch
                VStack(alignment: .leading, spacing: 10) {
                    Text("Apple Watch & Touch ID Unlock")
                        .font(.headline)

                    Text("MirrorLock uses macOS LocalAuthentication to allow seamless unlock via Touch ID, Apple Watch, or your system password.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Tap to unlock with Apple Watch", isOn: $preferences.appleWatchTapUnlock)
                        .font(.subheadline)
                    Text("When enabled, touching the keyboard or trackpad while locked sends a watch approval request (rate-limited to every 5s).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)

                    Toggle("Tap to unlock with Android Watch", isOn: $preferences.androidWatchTapUnlock)
                        .font(.subheadline)
                    Text("When enabled, touching the keyboard or trackpad while locked triggers unlock detection for compatible Android Wear OS companions.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)

                    HStack {
                        Button(isTesting ? "Testing..." : "Send Test to Apple Watch / Touch ID") {
                            isTesting = true
                            testAuthResult = nil
                            Authenticator.shared.testAuthentication { _, message in
                                isTesting = false
                                testAuthResult = message
                            }
                        }
                        .disabled(isTesting)

                        if let result = testAuthResult {
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(result.contains("succeeded") ? .green : .orange)
                        }
                    }
                    .padding(.top, 4)

                    Text("To use Apple Watch unlock, ensure 'Use Apple Watch to unlock your Mac and apps' is enabled in System Settings → Touch ID & Password.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                // Keyboard Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)

                    HStack {
                        Text("Activate Lock Shortcut")
                        Spacer()
                        Picker("", selection: $preferences.activateHotkey) {
                            Text("⌘⇧M (Default)").tag(HotkeyCombo.activate)
                            Text("⌘⇧L (Wardlume style)").tag(HotkeyCombo.activateWardlume)
                            Text("⌘⌥L").tag(HotkeyCombo.activateOption)
                        }
                        .frame(width: 200)
                    }

                    HStack {
                        Text("Unlock Shortcut")
                        Spacer()
                        Picker("", selection: $preferences.unlockHotkey) {
                            Text("⌘⇧U (Default)").tag(HotkeyCombo.unlock)
                        }
                        .frame(width: 200)
                    }

                    Divider()

                    Toggle("Enable Emergency Exit Shortcut", isOn: $preferences.emergencyExitEnabled)
                        .font(.subheadline.bold())

                    if preferences.emergencyExitEnabled {
                        HStack {
                            Text("Emergency Exit Shortcut")
                            Spacer()
                            Picker("", selection: $preferences.emergencyExitHotkey) {
                                Text("⌃⌥⌘Esc (Default)").tag(HotkeyCombo.emergencyExitDefault)
                                Text("⌃⇧⌘E").tag(HotkeyCombo.emergencyExitShiftE)
                            }
                            .frame(width: 200)
                        }
                        Text("⚠️ Emergency exit drops the lock immediately with NO authentication required.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
            }
            .padding(22)
        }
    }
}

// MARK: - Automation Tab

private struct AutomationTab: View {
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Automation & Power")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Keep Mac awake while locked", isOn: $preferences.keepMacAwake)
                        .font(.subheadline.bold())
                    Text("Prevents display sleep and idle system sleep while the mirror lock is active. Ensures your AI agents (Claude, Cursor, Copilot) continue executing without being suspended by macOS energy saver.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
                        .font(.subheadline.bold())
                    Text("Starts MirrorLock automatically in the menu bar when your Mac boots up, so it's always ready.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-lock when idle")
                                .font(.subheadline.bold())
                            Text("Automatically activates MirrorLock after a period of user inactivity.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $preferences.autoLockIdleMinutes) {
                            Text("Disabled").tag(0)
                            Text("1 minute").tag(1)
                            Text("2 minutes").tag(2)
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                        }
                        .frame(width: 140)
                    }

                    if preferences.autoLockIdleMinutes > 0 {
                        Text("A 10-second cancelable countdown HUD appears before locking. Moving the pointer or pressing any key cancels the auto-lock.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
            }
            .padding(22)
        }
    }
}

// MARK: - Displays & Safety Tab

private struct DisplaysTab: View {
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Multi-Display & Safety")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Black out secondary displays while locked", isOn: $preferences.blackoutSecondaryScreens)
                        .font(.subheadline.bold())
                    Text("When active, MirrorLock shows the live desktop mirror on your primary display and shields secondary monitors in pure black.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Safety Guarantees")
                        .font(.subheadline.bold())

                    SafetyBullet(
                        icon: "cable.connector",
                        text: "Display Reconnection Safe: Connecting or disconnecting monitors never crashes or unlocks the Mac."
                    )
                    SafetyBullet(
                        icon: "moon.stars",
                        text: "Sleep/Wake Safe: System sleep or closing the MacBook lid safely deactivates the lock."
                    )
                    SafetyBullet(
                        icon: "xmark.app",
                        text: "Force Quit Available: ⌘⌥Esc is reserved by macOS and can force quit MirrorLock at any time."
                    )
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(12)
            }
            .padding(22)
        }
    }
}

// MARK: - Permissions Tab

private struct PermissionsTab: View {
    @EnvironmentObject var lockState: LockState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Required Permissions")
                    .font(.headline)

                PermissionRow(
                    title: "Screen Recording",
                    detail: "Mirrors your live desktop behind the overlay.",
                    granted: lockState.screenRecordingGranted,
                    action: PermissionHelper.openScreenRecordingSettings
                )
                PermissionRow(
                    title: "Accessibility",
                    detail: "Locks keyboard, mouse, and trackpad at event-tap level.",
                    granted: lockState.accessibilityGranted,
                    action: PermissionHelper.openAccessibilitySettings
                )
                PermissionRow(
                    title: "Input Monitoring",
                    detail: "Detects intrusion attempts and global shortcuts.",
                    granted: lockState.inputMonitoringGranted,
                    action: PermissionHelper.openInputMonitoringSettings
                )

                Divider()

                HStack {
                    Button("Request All Permissions") {
                        PermissionHelper.requestScreenRecording()
                        PermissionHelper.requestInputPermissions()
                    }
                    Button("Refresh Status") {
                        lockState.recheckPermissions()
                    }
                }

                Text("Permissions are used solely on your local Mac while locked. No analytics, tracking, or network transmission occurs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .onAppear { lockState.recheckPermissions() }
        }
    }
}

// MARK: - Subcomponents

private struct StepRow: View {
    let number: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SafetyBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let label: String
    let active: Bool
    let activeText: String
    let inactiveText: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text("\(label): \(active ? activeText : inactiveText)")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(6)
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !granted {
                Button("Open Settings", action: action)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
