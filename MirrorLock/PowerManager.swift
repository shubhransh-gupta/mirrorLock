import Foundation
import IOKit.pwr_mgt

@MainActor
final class PowerManager {
    static let shared = PowerManager()

    private var assertionID: IOPMAssertionID = 0
    private(set) var isPreventingSleep = false

    private init() {}

    /// Prevents display and system sleep while MirrorLock is active so running AI agents continue uninterrupted.
    func preventSleep(reason: String = "MirrorLock active - keeping display and system awake for running agents") {
        guard !isPreventingSleep else { return }

        let flags = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        let result = IOPMAssertionCreateWithName(
            flags,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )

        if result == kIOReturnSuccess {
            isPreventingSleep = true
        }
    }

    /// Releases the sleep prevention assertion, restoring normal energy saver behavior.
    func allowSleep() {
        guard isPreventingSleep else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isPreventingSleep = false
    }
}
