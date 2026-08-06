import AppKit

@MainActor
final class MirrorOverlay {
    let window: NSWindow
    let imageView: NSImageView
    let dimLayer: CALayer
    let statusPill: NSView
    let hintPill: NSView

    init(screenFrame: NSRect, unlockHint: String) {
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

        let statusPill = MirrorOverlay.makeStatusPill(in: container)
        let hintPill = MirrorOverlay.makeHintPill(in: container, text: unlockHint)

        window.contentView = container
        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.imageView = imageView
        self.dimLayer = dimLayer
        self.statusPill = statusPill
        self.hintPill = hintPill
    }

    func flashOnIntrusion() {
        CATransaction.begin()
        flashPill(statusPill)
        flashPill(hintPill)
        CATransaction.commit()
    }

    private func flashPill(_ pill: NSView) {
        guard let layer = pill.layer else { return }
        let dark = NSColor.black.withAlphaComponent(0.65).cgColor
        let red = NSColor.systemRed.withAlphaComponent(0.75).cgColor
        let flash = CABasicAnimation(keyPath: "backgroundColor")
        flash.fromValue = dark
        flash.toValue = red
        flash.duration = 0.3
        flash.autoreverses = true
        layer.add(flash, forKey: "intrusionFlash")
    }

    private static func makeStatusPill(in container: NSView) -> NSView {
        let pillW: CGFloat = 90, pillH: CGFloat = 44
        let pill = NSView(frame: CGRect(
            x: (container.bounds.width - pillW) / 2,
            y: container.bounds.height - 80,
            width: pillW, height: pillH
        ))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.65).cgColor
        pill.layer?.cornerRadius = 14
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        pill.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]

        let config = NSImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        if let symbol = NSImage(systemSymbolName: "lock.rectangle.on.rectangle",
                                accessibilityDescription: "Locked")?
            .withSymbolConfiguration(config) {
            let iv = NSImageView(frame: CGRect(x: 12, y: 10, width: 24, height: 24))
            iv.image = symbol
            iv.contentTintColor = .white
            pill.addSubview(iv)
        }

        let label = NSTextField(labelWithString: "Mirrored")
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.frame = CGRect(x: 40, y: 14, width: 50, height: 16)
        pill.addSubview(label)

        container.addSubview(pill)
        return pill
    }

    private static func makeHintPill(in container: NSView, text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.sizeToFit()

        let padX: CGFloat = 18, padY: CGFloat = 10
        let pillW = label.frame.width + padX * 2
        let pillH = label.frame.height + padY * 2

        let pill = NSView(frame: CGRect(
            x: (container.bounds.width - pillW) / 2,
            y: 36,
            width: pillW, height: pillH
        ))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.65).cgColor
        pill.layer?.cornerRadius = pillH / 2
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        pill.autoresizingMask = [.minXMargin, .maxXMargin, .maxYMargin]
        pill.alphaValue = 0

        label.frame = CGRect(x: padX, y: padY, width: label.frame.width, height: label.frame.height)
        pill.addSubview(label)
        container.addSubview(pill)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.8
                pill.animator().alphaValue = 0.8
            }
        }

        return pill
    }
}
