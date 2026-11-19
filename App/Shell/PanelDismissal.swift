import AppKit
import SwiftUI

enum PanelDismissal {
    static func dismissMenuBarPanel() {
        for window in NSApp.windows where window.canBecomeKey && window.isVisible {
            let className = String(describing: type(of: window))
            if className.contains("NSStatusBarWindow") || className.contains("NSPanel") {
                window.orderOut(nil)
                return
            }
        }
        if let key = NSApp.keyWindow, key.canBecomeKey {
            key.orderOut(nil)
        }
    }
}

struct ClickOutsideMonitor: NSViewRepresentable {
    let enabled: Bool
    let onOutsideClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = MonitorView()
        view.onOutsideClick = onOutsideClick
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? MonitorView else { return }
        view.onOutsideClick = onOutsideClick
        if enabled {
            view.startMonitoring()
        } else {
            view.stopMonitoring()
        }
    }

    final class MonitorView: NSView {
        var onOutsideClick: (() -> Void)?
        private var globalMonitor: Any?
        private var localMonitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }

        func startMonitoring() {
            guard globalMonitor == nil else { return }
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.onOutsideClick?()
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self, let window = self.window, let content = window.contentView else {
                    self?.onOutsideClick?()
                    return event
                }
                let point = content.convert(event.locationInWindow, from: nil)
                if content.hitTest(point) == nil {
                    self.onOutsideClick?()
                }
                return event
            }
        }

        func stopMonitoring() {
            if let globalMonitor {
                NSEvent.removeMonitor(globalMonitor)
                self.globalMonitor = nil
            }
            if let localMonitor {
                NSEvent.removeMonitor(localMonitor)
                self.localMonitor = nil
            }
        }

        deinit {
            stopMonitoring()
        }
    }
}