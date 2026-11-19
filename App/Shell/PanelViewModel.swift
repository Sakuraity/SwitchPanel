import Foundation
import SwiftUI

struct ToggleRowModel: Identifiable {
    let id: ToggleID
    let toggle: SystemToggle
    var snapshot: ToggleSnapshot
    var isBusy: Bool

    var isAction: Bool { toggle.kind == .action }
    var usesToggleControl: Bool { toggle.presentsAsToggleRow }
}

@MainActor
final class PanelViewModel: ObservableObject {
    @Published var rows: [ToggleRowModel] = []
    @Published var loginItem = LaunchAtLogin.shared

    private let registry = ToggleRegistry.shared
    private let store = PreferencesStore.shared

    func reloadToggleList() {
        let toggles = registry.orderedVisibleToggles(
            order: store.toggleOrder,
            hidden: store.hiddenToggleIDs
        )
        rows = toggles.map {
            ToggleRowModel(id: $0.id, toggle: $0, snapshot: ToggleSnapshot(isOn: false, errorMessage: nil), isBusy: false)
        }
    }

    func refreshAll() async {
        for index in rows.indices {
            let snapshot = await rows[index].toggle.refresh()
            rows[index].snapshot = snapshot
        }
        await MenuBarStatusModel.shared.refresh()
    }

    func performToggle(at index: Int, turnOn: Bool) async {
        guard rows.indices.contains(index) else { return }
        let row = rows[index]
        if row.id == .emptyTrash, !turnOn { return }

        let previous = rows[index].snapshot
        if rows[index].id == .darkMode {
            AppearanceToggleTracer.markTap()
        }
        rows[index].isBusy = true
        rows[index].snapshot.errorMessage = nil

        let momentaryToggle = rows[index].id == .emptyTrash
        let stateful = rows[index].toggle.kind == .stateful || momentaryToggle

        if stateful {
            withAnimation(PanelMotion.toggleSpring) {
                rows[index].snapshot = ToggleSnapshot(
                    isOn: momentaryToggle ? true : turnOn,
                    errorMessage: nil,
                    isEnabled: rows[index].snapshot.isEnabled
                )
            }
        }
        if rows[index].id == .darkMode, rows[index].toggle.kind == .stateful {
            await MenuBarStatusModel.shared.refresh(darkModeOn: turnOn)
        }
        do {
            try await rows[index].toggle.perform(turnOn: turnOn)
            if momentaryToggle {
                withAnimation(PanelMotion.toggleSpring) {
                    rows[index].snapshot = ToggleSnapshot(isOn: false, errorMessage: nil)
                }
            }
        } catch {
            if momentaryToggle {
                withAnimation(PanelMotion.toggleSpring) {
                    rows[index].snapshot = ToggleSnapshot(
                        isOn: false,
                        errorMessage: error.localizedDescription,
                        isEnabled: previous.isEnabled
                    )
                }
            } else {
                withAnimation(PanelMotion.toggleSpring) {
                    rows[index].snapshot = previous
                    rows[index].snapshot.errorMessage = error.localizedDescription
                }
                if rows[index].id == .darkMode {
                    await MenuBarStatusModel.shared.refresh(darkModeOn: previous.isOn)
                }
            }
        }
        rows[index].isBusy = false
        if rows[index].id != .darkMode {
            await MenuBarStatusModel.shared.refresh()
        }
    }

    func performAction(at index: Int) async {
        await performToggle(at: index, turnOn: true)
    }
}