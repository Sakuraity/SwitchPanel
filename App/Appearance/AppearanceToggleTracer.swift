import Foundation
import os

/// Click-to-theme-change intervals (tap → engine → distributed notification).
enum AppearanceToggleTracer {
    private static let logger = Logger(subsystem: "dev.kangyuan.switchpanel", category: "appearance")

    private static var tapUptime: UInt64?
    private static var engine: String?
    private static var observer: NSObjectProtocol?

    static func markTap() {
        tapUptime = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        engine = nil
        installThemeObserverIfNeeded()
    }

    static func markEngineReturned(method: String) {
        engine = method
        guard let tapUptime else { return }
        let ms = Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - tapUptime) / 1_000_000
        logger.info("appearance engine=\(method, privacy: .public) returned \(ms, format: .fixed(precision: 1))ms after tap")
    }

    private static func installThemeObserverIfNeeded() {
        guard observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil
        ) { _ in
            guard let start = tapUptime else { return }
            let ms = Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - start) / 1_000_000
            let method = engine ?? "unknown"
            logger.info("appearance themeChanged \(ms, format: .fixed(precision: 1))ms after tap engine=\(method, privacy: .public)")
            tapUptime = nil
            engine = nil
        }
    }

}