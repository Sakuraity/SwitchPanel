import AppKit
import Foundation

/// Low Power Mode via Apple's documented `pmset` tool (`man pmset`). Writes require administrator approval once per app session (cached `AuthorizationRef`).
enum LowPowerModeService {
    private static let pmsetPath = "/usr/bin/pmset"

    static var isSupported: Bool {
        guard let output = runPmset(arguments: ["-g"]) else { return false }
        return output.contains("lowpowermode")
    }

    static func currentIsOn() -> Bool? {
        guard isSupported, let output = runPmset(arguments: ["-g"]) else { return nil }
        return LowPowerModeParser.activeLowPowerMode(from: output)
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isSupported else {
            throw ToggleError.unknown("此 Mac 不支持低电量模式（多为无电池的台式机）。")
        }
        let flag = enabled ? "1" : "0"

        if !runPmsetWithoutAdmin(arguments: ["-a", "lowpowermode", flag]) {
            try AdminAuthorization.shared.runPmset(arguments: ["-a", "lowpowermode", flag])
        }

        guard let actual = currentIsOn(), actual == enabled else {
            throw ToggleError.unknown("低电量模式未更改，请确认管理员授权。")
        }
    }

    /// Unprivileged attempt — returns whether pmset exited 0.
    @discardableResult
    private static func runPmsetWithoutAdmin(arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pmsetPath)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    static func runPmset(arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pmsetPath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

enum LowPowerModeParser {
    /// Parses `lowpowermode` under the `Currently in use:` section of `pmset -g`.
    static func activeLowPowerMode(from pmsetGOutput: String) -> Bool? {
        let lines = pmsetGOutput.components(separatedBy: .newlines)
        guard let startIndex = lines.firstIndex(where: { $0.contains("Currently in use:") }) else {
            return parseAnyLowPowerLine(from: pmsetGOutput)
        }
        for line in lines[(startIndex + 1)...] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasSuffix(":") { break }
            if let value = lowPowerValue(fromLine: trimmed) {
                return value
            }
        }
        return parseAnyLowPowerLine(from: pmsetGOutput)
    }

    private static func lowPowerValue(fromLine line: String) -> Bool? {
        guard line.lowercased().hasPrefix("lowpowermode") else { return nil }
        let parts = line.split(whereSeparator: { $0.isWhitespace })
        guard let last = parts.last, let intVal = Int(last) else { return nil }
        return intVal != 0
    }

    static func parseAnyLowPowerLine(from text: String) -> Bool? {
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.lowercased().hasPrefix("lowpowermode") else { continue }
            let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
            guard parts.count >= 2, let intVal = Int(parts.last ?? "") else { continue }
            return intVal != 0
        }
        return nil
    }
}