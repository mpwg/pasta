import AppKit
import ApplicationServices

/// AppKit is only used for macOS application services, not for our interface.
@MainActor
enum MacApplication {
    static var willTerminateNotification: Notification.Name { NSApplication.willTerminateNotification }

    static func activate() { NSApplication.shared.activate() }

    static func hideIfActive() {
        if NSApplication.shared.isActive { NSApplication.shared.hide(nil) }
    }

    static func quit() { NSApplication.shared.terminate(nil) }

    static func requestAccessibilityPermission() {
        // Request through Core Graphics; this also avoids the C API's mutable
        // global prompt constant under Swift 6 strict concurrency.
        if !CGPreflightPostEventAccess() { _ = CGRequestPostEventAccess() }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
