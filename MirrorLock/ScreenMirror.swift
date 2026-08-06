import ScreenCaptureKit
import CoreMedia
import CoreImage
import AppKit

@MainActor
protocol ScreenMirrorDelegate: AnyObject {
    func screenMirrorDidStop(_ mirror: ScreenMirror, error: Error?)
}

final class ScreenMirror: NSObject {
    private weak var imageView: NSImageView?
    weak var delegate: ScreenMirrorDelegate?

    private var stream: SCStream?
    nonisolated(unsafe) private var intentionalStop = false

    init(imageView: NSImageView) {
        self.imageView = imageView
    }

    func startCapture(excludingWindow overlayWindow: NSWindow) {
        Task {
            do {
                try await startCaptureTask(excludingWindow: overlayWindow)
            } catch {
                delegate?.screenMirrorDidStop(self, error: error)
            }
        }
    }

    func stopCapture() {
        guard let stream else { return }
        intentionalStop = true
        self.stream = nil
        Task { try? await stream.stopCapture() }
    }

    private func startCaptureTask(excludingWindow overlayWindow: NSWindow) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let display = content.displays.first else {
            throw MirrorError.noDisplay
        }

        let overlayID = CGWindowID(overlayWindow.windowNumber)
        let excluded = content.windows.filter { $0.windowID == overlayID }
        let filter = SCContentFilter(display: display, excludingWindows: excluded)

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let scale = screen.backingScaleFactor

        let config = SCStreamConfiguration()
        config.width = Int(screen.frame.width * scale)
        config.height = Int(screen.frame.height * scale)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.showsCursor = true

        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try await stream.startCapture()
        self.stream = stream
    }
}

extension ScreenMirror: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

        Task { @MainActor in
            self.imageView?.image = image
        }
    }
}

extension ScreenMirror: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        guard !intentionalStop else { return }
        Task { @MainActor in
            self.delegate?.screenMirrorDidStop(self, error: error)
        }
    }
}

enum MirrorError: Error {
    case noDisplay
}
