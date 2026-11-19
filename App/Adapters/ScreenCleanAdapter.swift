import Foundation

final class ScreenCleanAdapter: SystemToggle {
    let id: ToggleID = .screenClean
    let kind: ToggleKind = .stateful
    let title = "屏幕清洁"

    func refresh() async -> ToggleSnapshot {
        let active = await MainActor.run { ScreenCleanController.shared.isActive }
        return ToggleSnapshot(isOn: active, errorMessage: nil)
    }

    func perform(turnOn: Bool) async throws {
        await MainActor.run {
            if turnOn {
                ScreenCleanController.shared.enter()
                PanelDismissal.dismissMenuBarPanel()
            } else {
                ScreenCleanController.shared.exit(fromUserGesture: false)
            }
        }
    }
}