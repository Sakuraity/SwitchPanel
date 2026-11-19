import AppKit
import CoreFoundation
import Foundation

final class HideDesktopIconsAdapter: SystemToggle {
    let id: ToggleID = .hideDesktopIcons
    let kind: ToggleKind = .stateful
    let title = "隐藏桌面图标"

    private let domain = "com.apple.finder" as CFString
    private let key = "CreateDesktop" as CFString

    func refresh() async -> ToggleSnapshot {
        let createDesktop = readCreateDesktop()
        // CreateDesktop false => icons hidden => toggle "on" means hidden
        let hidden = createDesktop == false
        return ToggleSnapshot(isOn: hidden, errorMessage: nil)
    }

    func perform(turnOn: Bool) async throws {
        // turnOn true => hide icons => CreateDesktop false
        let value: CFBoolean = turnOn ? kCFBooleanFalse : kCFBooleanTrue
        CFPreferencesSetAppValue(key, value, domain)
        CFPreferencesAppSynchronize(domain)
        try restartFinder()
    }

    private func readCreateDesktop() -> Bool? {
        guard let raw = CFPreferencesCopyAppValue(key, domain) else {
            return true // default: show icons
        }
        if let number = raw as? NSNumber {
            return number.boolValue
        }
        if let boolean = raw as? Bool {
            return boolean
        }
        return true
    }

    private func restartFinder() throws {
        let finderID = "com.apple.finder"
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: finderID)
        for app in running {
            app.terminate()
        }

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 3 {
            if NSRunningApplication.runningApplications(withBundleIdentifier: finderID).isEmpty {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        if !NSRunningApplication.runningApplications(withBundleIdentifier: finderID).isEmpty {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            process.arguments = ["Finder"]
            try? process.run()
            process.waitUntilExit()
        }

        let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: finderURL, configuration: config) { _, error in
            if error != nil {
                // Surface on next refresh if needed
            }
        }
    }
}