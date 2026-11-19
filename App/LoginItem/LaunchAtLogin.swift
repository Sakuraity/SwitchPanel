import Foundation
import ServiceManagement
import Combine

@MainActor
final class LaunchAtLogin: ObservableObject {
    static let shared = LaunchAtLogin()

    @Published private(set) var status: SMAppService.Status = .notRegistered
    @Published private(set) var statusNote: String?

    private init() {
        refreshStatus()
    }

    func refreshStatus() {
        status = SMAppService.mainApp.status
        switch status {
        case .enabled:
            statusNote = nil
        case .requiresApproval:
            statusNote = "请在「系统设置 › 通用 › 登录项」中允许 Switch Panel。"
        case .notRegistered, .notFound:
            statusNote = nil
        @unknown default:
            statusNote = nil
        }
    }

    var isOn: Bool {
        status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshStatus()
        } catch {
            statusNote = "无法更新登录项：\(error.localizedDescription)"
            refreshStatus()
        }
    }
}