import Foundation
import IOKit
import IOKit.graphics

/// Main-display brightness via public IOKit display parameters (when hardware supports it).
enum DisplayBrightness {
    private static func primaryDisplayService() -> io_service_t? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        ) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        let service = IOIteratorNext(iterator)
        return service == 0 ? nil : service
    }

    static func readMain() -> Float? {
        guard let service = primaryDisplayService() else { return nil }
        defer { IOObjectRelease(service) }
        var value: Float = 0
        guard IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &value) == KERN_SUCCESS else {
            return nil
        }
        return value
    }

    static func writeMain(_ value: Float) -> Bool {
        guard let service = primaryDisplayService() else { return false }
        defer { IOObjectRelease(service) }
        let clamped = min(max(value, 0), 1)
        return IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, clamped) == KERN_SUCCESS
    }
}