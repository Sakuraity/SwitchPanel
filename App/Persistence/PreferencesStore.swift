import Foundation
import Combine

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    private enum Keys {
        static let schemaVersion = "preferences.schemaVersion"
        static let toggleOrder = "preferences.toggleOrder"
        static let hiddenToggleIDs = "preferences.hiddenToggleIDs"
        static let keepAwakeDesired = "preferences.keepAwakeDesired"
    }

    static let currentSchemaVersion = 1

    @Published private(set) var toggleOrder: [ToggleID]
    @Published private(set) var hiddenToggleIDs: Set<ToggleID>
    @Published var keepAwakeDesired: Bool {
        didSet {
            defaults.set(keepAwakeDesired, forKey: Keys.keepAwakeDesired)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.schemaVersion: Self.currentSchemaVersion,
            Keys.keepAwakeDesired: false,
        ])

        let storedVersion = defaults.integer(forKey: Keys.schemaVersion)
        if storedVersion != Self.currentSchemaVersion {
            defaults.set(Self.currentSchemaVersion, forKey: Keys.schemaVersion)
        }

        toggleOrder = Self.loadToggleOrder(from: defaults)
        hiddenToggleIDs = Self.loadHidden(from: defaults)
        keepAwakeDesired = defaults.bool(forKey: Keys.keepAwakeDesired)
    }

    static func loadToggleOrder(from defaults: UserDefaults) -> [ToggleID] {
        mergeOrder(stored: defaults.stringArray(forKey: Keys.toggleOrder) ?? [])
    }

    static func loadHidden(from defaults: UserDefaults) -> Set<ToggleID> {
        let raw = defaults.stringArray(forKey: Keys.hiddenToggleIDs) ?? []
        let known = Set(ToggleID.allCases.map(\.rawValue))
        return Set(raw.filter { known.contains($0) }.compactMap(ToggleID.init(rawValue:)))
    }

    /// Drops unknown ids, appends missing known ids at the end.
    static func mergeOrder(stored: [String]) -> [ToggleID] {
        let knownIDs = Set(ToggleID.allCases.map(\.rawValue))
        var order = stored.filter { knownIDs.contains($0) }.compactMap(ToggleID.init(rawValue:))
        for id in ToggleID.defaultOrder where !order.contains(id) {
            order.append(id)
        }
        return order
    }

    func setToggleOrder(_ order: [ToggleID]) {
        let merged = Self.mergeOrder(stored: order.map(\.rawValue))
        toggleOrder = merged
        defaults.set(merged.map(\.rawValue), forKey: Keys.toggleOrder)
    }

    func moveToggle(from source: IndexSet, to destination: Int) {
        var order = toggleOrder
        order.move(fromOffsets: source, toOffset: destination)
        setToggleOrder(order)
    }

    func setHidden(_ hidden: Set<ToggleID>) {
        let filtered = hidden.filter { ToggleID.allCases.contains($0) }
        hiddenToggleIDs = Set(filtered)
        defaults.set(filtered.map(\.rawValue), forKey: Keys.hiddenToggleIDs)
    }

    func isHidden(_ id: ToggleID) -> Bool {
        hiddenToggleIDs.contains(id)
    }

    func setHidden(_ id: ToggleID, hidden: Bool) {
        var set = hiddenToggleIDs
        if hidden {
            set.insert(id)
        } else {
            set.remove(id)
        }
        setHidden(set)
    }
}