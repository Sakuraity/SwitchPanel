import AppKit
import CoreFoundation
import Foundation
import os.log

/// System-wide appearance — single System Events transition; prefs sync afterward (no pre-sync flash).
enum SystemAppearance {
    private static let logger = Logger(subsystem: "dev.kangyuan.switchpanel", category: "appearance")
    private static let styleKey = "AppleInterfaceStyle" as CFString
    private static let autoStyleKey = "AppleInterfaceStyleSwitchesAutomatically" as CFString
    private static let themeChangedNotification = "AppleInterfaceThemeChangedNotification" as CFString
    private static let aquaVariantNotification = "AppleAquaColorVariantChanged" as CFString

    static func currentIsDark() -> Bool {
        if let sky = SkyLightAppearance.currentIsDark() {
            return sky
        }
        if let script = try? AppleScriptBridge.readDarkMode() {
            return script
        }
        return isDark(interfaceStyle: interfaceStyleValue())
    }

    static func isDark(interfaceStyle value: String?) -> Bool {
        value == "Dark"
    }

    static func interfaceStyleValue() -> String? {
        CFPreferencesCopyAppValue(styleKey, kCFPreferencesAnyApplication) as? String
    }

    /// SkyLight when available; sync global prefs immediately after so WebKit/Chromium follow (no async race).
    static func setDarkMode(_ enabled: Bool) throws {
        if SkyLightAppearance.setDarkMode(enabled) {
            AppearanceToggleTracer.markEngineReturned(method: "skylight")
            mirrorGlobalAppearancePreferences(enabled: enabled)
            return
        }
        do {
            try AppleScriptBridge.setDarkMode(enabled)
            AppearanceToggleTracer.markEngineReturned(method: "applescript")
        } catch ToggleError.automationDenied {
            try applyPrefsOnlyFallback(enabled: enabled)
            AppearanceToggleTracer.markEngineReturned(method: "prefs-fallback")
            return
        }
        mirrorGlobalAppearancePreferences(enabled: enabled)
    }

    private static func applyPrefsOnlyFallback(enabled: Bool) throws {
        mirrorGlobalAppearancePreferences(enabled: enabled)
        guard currentIsDark() == enabled else {
            throw ToggleError.automationDenied
        }
    }

    /// After WindowServer/AppleScript set — flush globals, then re-broadcast so Chromium picks up committed prefs.
    private static function mirrorGlobalAppearancePreferences(enabled: Bool) {
        disableAutoAppearanceIfNeeded()
        syncInterfaceStylePreference(enabled)
        broadcastAppearancePreferencesCommitted()
        logger.debug("prefs mirrored dark=\(enabled) style=\(interfaceStyleValue() ?? "Light", privacy: .public)")
    }

    /// SkyLight can post before `AppleInterfaceStyle` is flushed; Chrome observes `NSApp.effectiveAppearance` after prefs + notify.
    private static func broadcastAppearancePreferencesCommitted() {
        let center = CFNotificationCenterGetDistributedCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(themeChangedNotification),
            nil,
            nil,
            true
        )
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(aquaVariantNotification),
            nil,
            nil,
            true
        )
    }

    private static func disableAutoAppearanceIfNeeded() {
        guard isAutoAppearanceEnabled() else { return }
        CFPreferencesSetValue(
            autoStyleKey,
            kCFBooleanFalse,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }

    private static func isAutoAppearanceEnabled() -> Bool {
        guard let value = CFPreferencesCopyAppValue(autoStyleKey, kCFPreferencesAnyApplication) else {
            return false
        }
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }

    private static func syncInterfaceStylePreference(_ enabled: Bool) {
        if enabled {
            CFPreferencesSetValue(
                styleKey,
                "Dark" as CFString,
                kCFPreferencesAnyApplication,
                kCFPreferencesCurrentUser,
                kCFPreferencesAnyHost
            )
        } else {
            CFPreferencesSetValue(
                styleKey,
                nil,
                kCFPreferencesAnyApplication,
                kCFPreferencesCurrentUser,
                kCFPreferencesAnyHost
            )
        }
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
    }
}

enum AppleScriptBridge {
    private static let readScript = makeScript("""
    tell application "System Events"
        tell appearance preferences
            get dark mode
        end tell
    end tell
    """)

    private static let setDarkOnScript = makeScript("""
    tell application "System Events"
        tell appearance preferences
            set dark mode to true
        end tell
    end tell
    """)

    private static let setDarkOffScript = makeScript("""
    tell application "System Events"
        tell appearance preferences
            set dark mode to false
        end tell
    end tell
    """)

    /// Keeps System Events warm — avoids cold-launch latency on first toggle after app start.
    static func warmUpIfAutomationAllowed() {
        _ = try? readDarkMode()
    }

    static func readDarkMode() throws -> Bool {
        let descriptor = try execute(precompiled: readScript, fallback: readScript.source)
        if let string = descriptor.stringValue?.lowercased(), !string.isEmpty {
            return string == "true" || string == "yes"
        }
        return descriptor.booleanValue
    }

    static func setDarkMode(_ enabled: Bool) throws {
        let template = enabled ? setDarkOnScript : setDarkOffScript
        _ = try execute(precompiled: template, fallback: template.source)
    }

    private struct PrecompiledScript {
        let source: String
        let script: NSAppleScript?
    }

    private static func makeScript(_ source: String) -> PrecompiledScript {
        PrecompiledScript(source: source, script: NSAppleScript(source: source))
    }

    private static func execute(precompiled: PrecompiledScript, fallback source: String) throws -> NSAppleEventDescriptor {
        var errorInfo: NSDictionary?
        let runner = precompiled.script ?? NSAppleScript(source: source)
        guard let runner else {
            throw ToggleError.scriptFailed("无法创建脚本")
        }
        let output = runner.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 {
                throw ToggleError.automationDenied
            }
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "未知错误"
            throw ToggleError.scriptFailed(message)
        }
        return output
    }
}