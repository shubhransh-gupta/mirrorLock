import AppKit

@MainActor
final class IntruderAlert {
    private var lastTriggered: TimeInterval = 0
    private let cooldown: TimeInterval = 3.0
    private var flashWindow: NSWindow?

    func trigger(on screen: NSScreen?) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTriggered > cooldown else { return }
        lastTriggered = now

        playAlertSound()
        flashBorder(on: screen)
    }

    private func playAlertSound() {
        NSSound(named: "Funk")?.play()
    }

    private func flashBorder(on screen: NSScreen?) {
        let frame = screen?.frame ?? NSScreen.main?.frame ?? .zero

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true

        let borderView = NSView(frame: frame)
        borderView.wantsLayer = true
        borderView.layer?.borderWidth = 8
        borderView.layer?.borderColor = NSColor.systemRed.cgColor
        borderView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = borderView
        window.makeKeyAndOrderFront(nil)

        flashWindow = window

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            borderView.animator().alphaValue = 0.3
        } completionHandler: { [weak self] in
            window.close()
            Task { @MainActor in self?.flashWindow = nil }
        }
    }
}
