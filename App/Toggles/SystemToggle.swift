import Foundation

enum ToggleKind {
    case stateful
    case action
}

struct ToggleSnapshot: Equatable {
    var isOn: Bool?
    var errorMessage: String?
    var isEnabled: Bool = true
}

protocol SystemToggle: AnyObject {
    var id: ToggleID { get }
    var kind: ToggleKind { get }
    var title: String { get }
    /// Stateful rows use a switch; momentary actions (e.g. empty trash) may still use switch chrome.
    var presentsAsToggleRow: Bool { get }

    func refresh() async -> ToggleSnapshot
    func perform(turnOn: Bool) async throws
}

extension SystemToggle {
    var presentsAsToggleRow: Bool { kind == .stateful }
}

enum ToggleError: LocalizedError {
    case automationDenied
    case finderAutomationDenied
    case accessibilityDenied
    case accessibilityRequired
    case finderRestartFailed
    case scriptFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .automationDenied:
            return "请在「系统设置 › 隐私与安全性 › 自动化」中允许本 App 控制「系统事件」。"
        case .finderAutomationDenied:
            return "请在「系统设置 › 隐私与安全性 › 自动化」中允许本 App 控制「访达」。"
        case .accessibilityDenied, .accessibilityRequired:
            return "请在「系统设置 › 隐私与安全性 › 辅助功能」中允许本 App。"
        case .finderRestartFailed:
            return "无法重启 Finder，请稍后重试。"
        case .scriptFailed(let detail):
            return "系统脚本失败：\(detail)"
        case .unknown(let detail):
            return detail
        }
    }
}