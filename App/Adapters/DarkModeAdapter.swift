import AppKit
import Foundation

final class DarkModeAdapter: SystemToggle {
    let id: ToggleID = .darkMode
    let kind: ToggleKind = .stateful
    let title = "深色模式"

    func refresh() async -> ToggleSnapshot {
        if let on = SkyLightAppearance.currentIsDark() {
            return ToggleSnapshot(isOn: on, errorMessage: nil)
        }
        do {
            let on = try AppleScriptBridge.readDarkMode()
            return ToggleSnapshot(isOn: on, errorMessage: nil)
        } catch ToggleError.automationDenied {
            let on = SystemAppearance.currentIsDark()
            return ToggleSnapshot(
                isOn: on,
                errorMessage: "无法读取系统外观。请在「自动化」中允许本 App 控制「系统事件」。"
            )
        } catch {
            let on = SystemAppearance.currentIsDark()
            return ToggleSnapshot(isOn: on, errorMessage: error.localizedDescription)
        }
    }

    func perform(turnOn: Bool) async throws {
        if SkyLightAppearance.isAvailable {
            try SystemAppearance.setDarkMode(turnOn)
            return
        }
        try await Task.detached(priority: .userInitiated) {
            try SystemAppearance.setDarkMode(turnOn)
        }.value
    }
}