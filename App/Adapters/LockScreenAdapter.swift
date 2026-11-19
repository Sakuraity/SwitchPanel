import AppKit
import CoreGraphics
import Foundation

final class LockScreenAdapter: SystemToggle {
    let id: ToggleID = .lockScreen
    let kind: ToggleKind = .action
    let title = "锁定屏幕"

    func refresh() async -> ToggleSnapshot {
        ToggleSnapshot(isOn: nil, errorMessage: nil)
    }

    func perform(turnOn: Bool) async throws {
        guard PermissionsCoordinator.isAccessibilityTrusted(prompt: true) else {
            throw ToggleError.accessibilityRequired
        }
        postLockScreenShortcut()
    }

  private func postLockScreenShortcut() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0x0C,
            keyDown: true
        )
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0x0C,
            keyDown: false
        )
        let flags: CGEventFlags = [.maskCommand, .maskControl]
        keyDown?.flags = flags
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}