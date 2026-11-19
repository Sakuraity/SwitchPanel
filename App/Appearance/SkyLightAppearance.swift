import Darwin
import Foundation

/// Private SkyLight SPI — local/unsigned build only; fastest system-wide appearance path on this macOS.
enum SkyLightAppearance {
    private static let frameworkPath =
        "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"

    typealias GetThemeFn = @convention(c) () -> Bool
    typealias SetThemeFn = @convention(c) (Bool) -> Void

    private final class Cache: @unchecked Sendable {
        let getTheme: GetThemeFn?
        let setTheme: SetThemeFn?

        init?() {
            guard let handle = dlopen(frameworkPath, RTLD_LAZY),
                  let getSym = dlsym(handle, "SLSGetAppearanceThemeLegacy"),
                  let setSym = dlsym(handle, "SLSSetAppearanceThemeLegacy")
            else { return nil }
            getTheme = unsafeBitCast(getSym, to: GetThemeFn.self)
            setTheme = unsafeBitCast(setSym, to: SetThemeFn.self)
        }
    }

    private static let cache = Cache()

    static var isAvailable: Bool { cache != nil }

    static func currentIsDark() -> Bool? {
        cache?.getTheme?()
    }

    static func setDarkMode(_ enabled: Bool) -> Bool {
        guard let setTheme = cache?.setTheme else { return false }
        setTheme(enabled)
        return true
    }
}