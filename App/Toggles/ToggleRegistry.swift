import Foundation

@MainActor
final class ToggleRegistry: ObservableObject {
    static let shared = ToggleRegistry()

  private(set) var toggles: [ToggleID: SystemToggle] = [:]

    private init() {
        register(DarkModeAdapter())
        register(HideDesktopIconsAdapter())
        register(KeepAwakeAdapter(store: .shared))
        register(LockScreenAdapter())
        register(EmptyTrashAdapter())
        register(ScreenCleanAdapter())
        register(LowPowerModeAdapter())
    }

    private func register(_ toggle: SystemToggle) {
        toggles[toggle.id] = toggle
    }

    func orderedVisibleToggles(order: [ToggleID], hidden: Set<ToggleID>) -> [SystemToggle] {
        let known = Set(ToggleID.allCases)
        var result: [SystemToggle] = []
        for id in order where known.contains(id) && !hidden.contains(id) {
            if let toggle = toggles[id] {
                result.append(toggle)
            }
        }
        for id in ToggleID.defaultOrder where !order.contains(id) && !hidden.contains(id) {
            if let toggle = toggles[id] {
                result.append(toggle)
            }
        }
        return result
    }
}