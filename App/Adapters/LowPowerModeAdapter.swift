import Foundation

final class LowPowerModeAdapter: SystemToggle {
    let id: ToggleID = .lowPowerMode
    let kind: ToggleKind = .stateful
    let title = "低电量模式"

    func refresh() async -> ToggleSnapshot {
        guard LowPowerModeService.isSupported else {
            return ToggleSnapshot(
                isOn: nil,
                errorMessage: "此 Mac 不支持低电量模式（常见于无电池的 Mac 台式机）。",
                isEnabled: false
            )
        }
        guard let isOn = LowPowerModeService.currentIsOn() else {
            return ToggleSnapshot(isOn: false, errorMessage: "无法读取低电量模式状态。", isEnabled: true)
        }
        return ToggleSnapshot(isOn: isOn, errorMessage: nil, isEnabled: true)
    }

    func perform(turnOn: Bool) async throws {
        try LowPowerModeService.setEnabled(turnOn)
    }
}