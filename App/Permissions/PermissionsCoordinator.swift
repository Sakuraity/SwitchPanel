import AppKit
import ApplicationServices

enum PermissionsCoordinator {
    static func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [key: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    static func requestAccessibility() -> Bool {
        isAccessibilityTrusted(prompt: true)
    }
}