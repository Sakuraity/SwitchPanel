import Foundation

final class KeepAwakeAdapter: SystemToggle {
    let id: ToggleID = .keepAwake
    let kind: ToggleKind = .stateful
    let title = "保持唤醒"

    private let store: PreferencesStore
    private var activity: NSObjectProtocol?

    init(store: PreferencesStore) {
        self.store = store
        if store.keepAwakeDesired {
            applyDesiredState(true)
        }
    }

    func refresh() async -> ToggleSnapshot {
        ToggleSnapshot(isOn: store.keepAwakeDesired, errorMessage: nil)
    }

    func perform(turnOn: Bool) async throws {
        store.keepAwakeDesired = turnOn
        applyDesiredState(turnOn)
    }

    func applyDesiredState(_ on: Bool) {
        if on {
            guard activity == nil else { return }
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
                reason: "Switch Panel 保持唤醒"
            )
        } else {
            if let activity {
                ProcessInfo.processInfo.endActivity(activity)
                self.activity = nil
            }
        }
    }

    func restoreOnLaunch() {
        applyDesiredState(store.keepAwakeDesired)
    }
}