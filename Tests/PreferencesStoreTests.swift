import XCTest
@testable import SwitchPanel

final class PreferencesStoreTests: XCTestCase {
    func testMergeOrderDropsUnknownAndAppendsMissing() {
        let merged = PreferencesStore.mergeOrder(stored: ["unknown", "keepAwake", "darkMode"])
        XCTAssertEqual(merged.first, .keepAwake)
        XCTAssertEqual(merged[1], .darkMode)
        XCTAssertTrue(merged.contains(.hideDesktopIcons))
        XCTAssertTrue(merged.contains(.lockScreen))
        XCTAssertFalse(merged.map(\.rawValue).contains("unknown"))
    }

    func testHiddenOnlyKeepsKnownIDs() {
        let defaults = UserDefaults(suiteName: "PreferencesStoreTests.\(UUID().uuidString)")!
        defaults.set(["darkMode", "notReal"], forKey: "preferences.hiddenToggleIDs")
        let hidden = PreferencesStore.loadHidden(from: defaults)
        XCTAssertEqual(hidden, [.darkMode])
    }

    func testDefaultOrderMatchesPhase1() {
        XCTAssertEqual(ToggleID.defaultOrder.count, 7)
        XCTAssertEqual(
            ToggleID.defaultOrder,
            [.darkMode, .hideDesktopIcons, .keepAwake, .lowPowerMode, .screenClean, .emptyTrash, .lockScreen]
        )
    }

    func testMergeOrderAppendsScreenCleanForLegacyStores() {
        let merged = PreferencesStore.mergeOrder(stored: ["darkMode", "keepAwake", "lockScreen"])
        XCTAssertTrue(merged.contains(.screenClean))
    }
}