import Foundation
import SwiftUI

@MainActor
final class MenuBarStatusModel: ObservableObject {
    static let shared = MenuBarStatusModel()

    /// `true` when any visible **stateful** switch in the panel reads as on (includes screen clean, keep awake, etc.).
    @Published private(set) var emphasizeChecked = false

    private init() {}

    func refresh(darkModeOn: Bool? = nil) async {
        let store = PreferencesStore.shared
        let registry = ToggleRegistry.shared
        let toggles = registry.orderedVisibleToggles(
            order: store.toggleOrder,
            hidden: store.hiddenToggleIDs
        )
        var anyOn = false
        for toggle in toggles where toggle.kind == .stateful {
            if toggle.id == .darkMode, let darkModeOn {
                if darkModeOn {
                    anyOn = true
                    break
                }
                continue
            }
            let snapshot = await toggle.refresh()
            if snapshot.isOn == true {
                anyOn = true
                break
            }
        }
        emphasizeChecked = anyOn
    }
}