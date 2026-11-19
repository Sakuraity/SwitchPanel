import XCTest
@testable import SwitchPanel

final class LowPowerModeParserTests: XCTestCase {
    func testParsesCurrentlyInUseSection() {
        let sample = """
        System-wide power settings:
        Currently in use:
         standby              1
         lowpowermode         1
         sleep                1
        Battery Power:
         lowpowermode         0
        """
        XCTAssertEqual(LowPowerModeParser.activeLowPowerMode(from: sample), true)
    }

    func testParsesOff() {
        let sample = """
        Currently in use:
         lowpowermode         0
        """
        XCTAssertEqual(LowPowerModeParser.activeLowPowerMode(from: sample), false)
    }
}