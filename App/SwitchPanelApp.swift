import AppKit
import SwiftUI

@main
struct SwitchPanelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var menuBarStatus = MenuBarStatusModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
        } label: {
            Image(nsImage: MenuBarIcon.statusImage(emphasizeChecked: menuBarStatus.emphasizeChecked))
                .accessibilityLabel("Switch Panel")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = ToggleRegistry.shared
        if let keepAwake = ToggleRegistry.shared.toggles[.keepAwake] as? KeepAwakeAdapter {
            keepAwake.restoreOnLaunch()
        }
        Task { await MenuBarStatusModel.shared.refresh() }
        Task.detached(priority: .utility) {
            AppleScriptBridge.warmUpIfAutomationAllowed()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AdminAuthorization.shared.invalidate()
    }
}