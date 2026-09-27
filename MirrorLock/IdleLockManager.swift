import AppKit
import SwiftUI
import CoreGraphics

@MainActor
final class IdleLockManager {
    static let shared = IdleLockManager()

    var onAutoLockTriggered: (() -> Void)?
    var isLockActive: (() -> Bool)?

    private var timer: Timer?
    private var countdownWindow: NSWindow?
    private var isCountingDown = false
    private var lastRecordedIdle: Double = 0

    private init() {}

    func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkIdleState()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        dismissCountdown()
    }

    private func checkIdleState() {
        let minutes = Preferences.shared.autoLockIdleMinutes
        guard minutes > 0 else {
            dismissCountdown()
            return
        }

        // If lock is already active, dismiss countdown and do nothing
        if isLockActive?() == true {
            dismissCountdown()
            return
        }

        guard let allEvents = CGEventType(rawValue: ~0) else { return }
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: allEvents)
        let threshold = Double(minutes * 60)
        let countdownWindowStart = max(0, threshold - 10.0)

        if idleSeconds < lastRecordedIdle - 0.5 {
            // User did something (moved mouse or pressed key)!
            dismissCountdown()
        }
        lastRecordedIdle = idleSeconds

        if idleSeconds >= threshold {
            dismissCountdown()
            onAutoLockTriggered?()
        } else if idleSeconds >= countdownWindowStart {
            let remaining = max(1, Int(ceil(threshold - idleSeconds)))
            showCountdown(remainingSeconds: remaining)
        } else {
            dismissCountdown()
        }
    }

    private func showCountdown(remainingSeconds: Int) {
        if let window = countdownWindow {
            (window.contentViewController as? NSHostingController<AutoLockCountdownView>)?.rootView =
                AutoLockCountdownView(
                    secondsRemaining: remainingSeconds,
                    onCancel: { [weak self] in self?.dismissCountdown() },
                    onLockNow: { [weak self] in
                        self?.dismissCountdown()
                        self?.onAutoLockTriggered?()
                    }
                )
            return
        }

        let view = AutoLockCountdownView(
            secondsRemaining: remainingSeconds,
            onCancel: { [weak self] in self?.dismissCountdown() },
            onLockNow: { [weak self] in
                self?.dismissCountdown()
                self?.onAutoLockTriggered?()
            }
        )

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 380
            let windowHeight: CGFloat = 64
            let x = screenRect.midX - (windowWidth / 2)
            let y = screenRect.maxY - windowHeight - 20
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        window.makeKeyAndOrderFront(nil)
        countdownWindow = window
        isCountingDown = true
    }

    func dismissCountdown() {
        guard isCountingDown || countdownWindow != nil else { return }
        countdownWindow?.close()
        countdownWindow = nil
        isCountingDown = false
    }
}
