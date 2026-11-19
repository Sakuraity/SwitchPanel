import XCTest
@testable import SwitchPanel

@MainActor
final class ToggleRegistryTests: XCTestCase {
    func testOrderedVisibleRespectsOrderAndHidden() async {
        let registry = ToggleRegistry.shared
        let order: [ToggleID] = [.lockScreen, .darkMode, .keepAwake, .hideDesktopIcons]
        let visible = registry.orderedVisibleToggles(order: order, hidden: [.hideDesktopIcons])
        XCTAssertEqual(
            visible.map(\.id),
            [.lockScreen, .darkMode, .keepAwake, .lowPowerMode, .screenClean, .emptyTrash]
        )
    }
}