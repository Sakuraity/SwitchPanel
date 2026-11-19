import Foundation
import Security

/// Caches a Security framework `AuthorizationRef` for the app lifetime to avoid repeated admin prompts.
final class AdminAuthorization {
    static let shared = AdminAuthorization()

    private var authRef: AuthorizationRef?
    private var hasCachedRights = false
    private let lock = NSLock()

    private init() {}

    deinit {
        freeAuthorization()
    }

    func runPmset(arguments: [String]) throws {
        try lock.withLock {
            try ensureAuthorization(promptUser: !hasCachedRights)
            try executePmset(arguments: arguments)
            hasCachedRights = true
        }
    }

    func invalidate() {
        lock.withLock {
            freeAuthorization()
        }
    }

    private func freeAuthorization() {
        hasCachedRights = false
        if let authRef {
            AuthorizationFree(authRef, [])
            self.authRef = nil
        }
    }

    private func ensureAuthorization(promptUser: Bool) throws {
        if authRef == nil {
            var created: AuthorizationRef?
            let status = AuthorizationCreate(nil, nil, [], &created)
            guard status == errAuthorizationSuccess, let created else {
                throw ToggleError.unknown("无法创建授权对象（\(status)）。")
            }
            authRef = created
        }
        guard let authRef else {
            throw ToggleError.unknown("未获得管理员授权。")
        }

        let flags: AuthorizationFlags = promptUser
            ? [.interactionAllowed, .extendRights, .preAuthorize]
            : [.extendRights, .preAuthorize]

        let status = withAdminItem { item in
            var rights = AuthorizationRights(count: 1, items: item)
            return AuthorizationCopyRights(authRef, &rights, nil, flags, nil)
        }

        guard status == errAuthorizationSuccess else {
            if promptUser {
                freeAuthorization()
            }
            if status == errAuthorizationCanceled {
                throw ToggleError.unknown("已取消管理员授权。")
            }
            throw ToggleError.unknown("管理员授权失败（\(status)）。")
        }
    }

    private func withAdminItem<R>(_ body: (UnsafeMutablePointer<AuthorizationItem>) -> R) -> R {
        "system.privilege.admin".withCString { name in
            var item = AuthorizationItem(name: name, valueLength: 0, value: nil, flags: 0)
            return withUnsafeMutablePointer(to: &item) { body($0) }
        }
    }

    private func executePmset(arguments: [String]) throws {
        guard let authRef else {
            throw ToggleError.unknown("未获得管理员授权。")
        }
        let status = SPAuthorizationRunPmset(authRef, arguments)
        guard status == errAuthorizationSuccess else {
            freeAuthorization()
            throw ToggleError.unknown("无法以管理员身份运行 pmset（\(status)）。")
        }
    }
}

private extension NSLock {
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try body()
    }
}