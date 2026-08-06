import AppKit

@MainActor
final class MirrorOverlay {
    let window: NSWindow
    let imageView: NSImageView
    let dimLayer: CALayer
    private let eyePill: NSView
    private var hideEyeTask: DispatchWorkItem?

    init(screenFrame: NSRect) {
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true

        let container = NSView(frame: screenFrame)
        container.wantsLayer = true

        let imageView = NSImageView(frame: container.bounds)
        imageView.imageScaling = .scaleAxesIndependently
        imageView.autoresizingMask = [.width, .height]
        container.addSubview(imageView)

        let dimLayer = CALayer()
        dimLayer.frame = container.bounds
        dimLayer.backgroundColor = NSColor.black.withAlphaComponent(0.25).cgColor
        dimLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        container.layer?.addSublayer(dimLayer)

        let eyePill = MirrorOverlay.makeEyePill(in: container)

        window.contentView = container
        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.imageView = imageView
        self.dimLayer = dimLayer
        self.eyePill = eyePill
    }

    /// Reveals the eye briefly when someone tries keyboard input while locked.
    func showEyeOnKeyboardIntrusion() {
        hideEyeTask?.cancel()

        eyePill.layer?.removeAnimation(forKey: "eyeFlash")
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            eyePill.animator().alphaValue = 0.9
        }

        let flash = CABasicAnimation(keyPath: "backgroundColor")
        flash.fromValue = NSColor.black.withAlphaComponent(0.65).cgColor
        flash.toValue = NSColor.systemRed.withAlphaComponent(0.75).cgColor
        flash.duration = 0.3
        flash.autoreverses = true
        eyePill.layer?.add(flash, forKey: "eyeFlash")

        let hide = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                self.eyePill.animator().alphaValue = 0
            }
        }
        hideEyeTask = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: hide)
    }

    private static func makeEyePill(in container: NSView) -> NSView {
        let pillSize: CGFloat = 52
        let pill = NSView(frame: CGRect(
            x: (container.bounds.width - pillSize) / 2,
            y: container.bounds.height - 88,
            width: pillSize,
            height: pillSize
        ))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.65).cgColor
        pill.layer?.cornerRadius = 14
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        pill.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]
        pill.alphaValue = 0

        let config = NSImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        if let symbol = NSImage(systemSymbolName: "eye.fill",
                                accessibilityDescription: "Watching")?
            .withSymbolConfiguration(config) {
            let iv = NSImageView(frame: CGRect(
                x: (pillSize - 28) / 2,
                y: (pillSize - 28) / 2,
                width: 28,
                height: 28
            ))
            iv.image = symbol
            iv.contentTintColor = .white
            pill.addSubview(iv)
        }

        container.addSubview(pill)
        return pill
    }
}
