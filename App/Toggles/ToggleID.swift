import Foundation

enum ToggleID: String, CaseIterable, Codable, Identifiable {
    case darkMode
    case hideDesktopIcons
    case keepAwake
    case lockScreen
    case emptyTrash
    case screenClean
    case lowPowerMode

    var id: String { rawValue }

    static let defaultOrder: [ToggleID] = [
        .darkMode,
        .hideDesktopIcons,
        .keepAwake,
        .lowPowerMode,
        .screenClean,
        .emptyTrash,
        .lockScreen,
    ]

    var displayName: String {
        switch self {
        case .darkMode: return "深色模式"
        case .hideDesktopIcons: return "隐藏桌面图标"
        case .keepAwake: return "保持唤醒"
        case .lockScreen: return "锁定屏幕"
        case .emptyTrash: return "清空废纸篓"
        case .screenClean: return "屏幕清洁"
        case .lowPowerMode: return "低电量模式"
        }
    }
}