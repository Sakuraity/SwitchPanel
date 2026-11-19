import AppKit
import Foundation

final class EmptyTrashAdapter: SystemToggle {
    let id: ToggleID = .emptyTrash
    let kind: ToggleKind = .action
    let title = "清空废纸篓"
    var presentsAsToggleRow: Bool { true }

    private static let emptyTrashScriptSource = """
    tell application "Finder"
        empty trash
    end tell
    """

    func refresh() async -> ToggleSnapshot {
        ToggleSnapshot(isOn: false, errorMessage: nil)
    }

    func perform(turnOn: Bool) async throws {
        guard turnOn else { return }
        try await Task.detached(priority: .userInitiated) {
            try Self.runEmptyTrashScript()
        }.value
    }

    private static func runEmptyTrashScript() throws {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: emptyTrashScriptSource) else {
            throw ToggleError.scriptFailed("无法创建脚本")
        }
        script.executeAndReturnError(&errorInfo)
        guard let errorInfo else { return }
        let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
        if code == -1743 {
            throw ToggleError.finderAutomationDenied
        }
        let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "未知错误"
        throw ToggleError.scriptFailed(message)
    }
}