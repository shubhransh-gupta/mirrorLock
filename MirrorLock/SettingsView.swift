import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lockState: LockState

    var body: some View {
        TabView {
            OverviewTab()
                .tabItem { Label("Overview", systemImage: "info.circle") }

            PermissionsTab()
                .tabItem { Label("Permissions", systemImage: "lock.shield") }

            ShortcutsTab()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(minWidth: 520, minHeight: 420)
        .onAppear { lockState.recheckPermissions() }
    }
}

private struct OverviewTab: View {
    @EnvironmentObject var lockState: LockState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image(systemName: "lock.rectangle.on.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("MirrorLock")
                        .font(.title.bold())
                    Text("Watch your AI work. Touch nothing.")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("MirrorLock shows your live desktop behind a dimmed mirror overlay while hard-locking keyboard, mouse, and trackpad. Perfect for leaving AI agents running while you step away.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                StatusBadge(label: "Lock", active: lockState.isLocked,
                            activeText: "Active", inactiveText: "Inactive")
                StatusBadge(label: "Permissions", active: lockState.allPermissionsReady,
                            activeText: "Ready", inactiveText: "Missing")
            }

            Spacer()

            Text("Press ⌘⇧M to lock · ⌘⇧U to unlock with Touch ID")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
    }
}

private struct PermissionsTab: View {
    @EnvironmentObject var lockState: LockState

    var body: some View {
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
                detail: "Locks keyboard, mouse, and trackpad.",
                granted: lockState.accessibilityGranted,
                action: PermissionHelper.openAccessibilitySettings
            )
            PermissionRow(
                title: "Input Monitoring",
                detail: "Detects intrusion attempts.",
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

            Text("Some permissions require quitting and reopening MirrorLock after granting.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .onAppear { lockState.recheckPermissions() }
    }
}

private struct ShortcutsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.headline)

            ShortcutRow(action: "Activate Mirror Lock", shortcut: "⌘⇧M")
            ShortcutRow(action: "Unlock with Touch ID", shortcut: "⌘⇧U")

            Divider()

            Text("Shortcuts work globally, even when MirrorLock is in the background.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
    }
}

private struct StatusBadge: View {
    let label: String
    let active: Bool
    let activeText: String
    let inactiveText: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(active ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text("\(label): \(active ? activeText : inactiveText)")
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
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

private struct ShortcutRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(6)
        }
    }
}
