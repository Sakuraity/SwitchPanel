import AppKit
import XCTest
@testable import SwitchPanel

final class SystemAppearanceTests: XCTestCase {
    func testIsDarkWhenKeyDark() {
        XCTAssertTrue(SystemAppearance.isDark(interfaceStyle: "Dark"))
    }

    func testIsDarkWhenKeyMissingOrLight() {
        XCTAssertFalse(SystemAppearance.isDark(interfaceStyle: nil))
        XCTAssertFalse(SystemAppearance.isDark(interfaceStyle: "Light"))
        XCTAssertFalse(SystemAppearance.isDark(interfaceStyle: "Automatic"))
    }

    func testBooleanDescriptorParsingContract() {
        XCTAssertTrue(NSAppleEventDescriptor(boolean: true).booleanValue)
        XCTAssertFalse(NSAppleEventDescriptor(boolean: false).booleanValue)
    }
}