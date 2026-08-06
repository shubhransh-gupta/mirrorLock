import AppKit
import Combine
import CoreGraphics

@MainActor
final class LockState: ObservableObject {
    @Published var isLocked = false
    @Published private(set) var screenRecordingGranted = false
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false

    var onToggle: (() -> Void)?

    var allPermissionsReady: Bool {
        screenRecordingGranted && accessibilityGranted && inputMonitoringGranted
    }

    func toggle() { onToggle?() }

    func recheckPermissions() {
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
        accessibilityGranted = InputGuard.accessibilityGranted()
        inputMonitoringGranted = InputGuard.inputMonitoringGranted()
    }
}
