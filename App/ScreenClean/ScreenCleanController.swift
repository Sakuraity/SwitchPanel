import AppKit
import Foundation
import IOKit.pwr_mgt

extension Notification.Name {
    static let screenCleanStateDidChange = Notification.Name("screenCleanStateDidChange")
}

@MainActor
final class ScreenCleanController {
    static let shared = ScreenCleanController()

    private(set) var isActive = false
    private var windows: [ScreenCleanWindow] = []
    private var keyMonitor: Any?
    private var savedBrightness: Float?
    private var didDimBrightness = false

    private init() {}

    func enter() {
        guard !isActive else { return }
        wakeAllDisplays()
        if let current = DisplayBrightness.readMain() {
            savedBrightness = current
            let dimmed = max(current * 0.15, 0.01)
            didDimBrightness = DisplayBrightness.writeMain(dimmed)
        } else {
            savedBrightness = nil
            didDimBrightness = false
        }

        windows = NSScreen.screens.map { screen in
            let window = ScreenCleanWindow(screen: screen) { [weak self] in
                Task { @MainActor in
                    self?.exit(fromUserGesture: true)
                }
            }
            window.orderFrontRegardless()
            return window
        }
        windows.first?.makeKeyAndOrderFront(nil)
        installKeyMonitor()
        isActive = true
        NotificationCenter.default.post(name: .screenCleanStateDidChange, object: nil)
    }

    func exit(fromUserGesture: Bool = false) {
        guard isActive else { return }
        removeKeyMonitor()
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows = []
        if didDimBrightness, let savedBrightness {
            _ = DisplayBrightness.writeMain(savedBrightness)
        }
        savedBrightness = nil
        didDimBrightness = false
        wakeAllDisplays()
        isActive = false
        NotificationCenter.default.post(name: .screenCleanStateDidChange, object: nil)
        _ = fromUserGesture
    }

    private func wakeAllDisplays() {
        var assertionID: IOPMAssertionID = 0
        let reason = "Switch Panel 屏幕清洁" as CFString
        if IOPMAssertionDeclareUserActivity(reason, kIOPMUserActiveLocal, &assertionID) == kIOReturnSuccess {
            IOPMAssertionRelease(assertionID)
        }
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                Task { @MainActor in
                    self.exit(fromUserGesture: true)
                }
                return nil
            }
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}

private final class ScreenCleanWindow: NSWindow {
    private let onExit: () -> Void

    init(screen: NSScreen, onExit: @escaping () -> Void) {
        self.onExit = onExit
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: true)
        level = .screenSaver
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        contentView = ScreenCleanContentView(onExit: onExit)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class ScreenCleanContentView: NSView {
    private let onExit: () -> Void

    init(onExit: @escaping () -> Void) {
        self.onExit = onExit
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let label = NSTextField(labelWithString: "轻点任意处，或按 Esc\n完成清洁")
        label.textColor = NSColor(white: 0.35, alpha: 1)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.alignment = .center
        label.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        onExit()
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onExit()
        }
    }
}