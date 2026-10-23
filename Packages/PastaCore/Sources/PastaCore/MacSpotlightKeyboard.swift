// SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
// SPDX-License-Identifier: GPL-3.0-or-later

import AppKit
import ApplicationServices
import Carbon.HIToolbox

@MainActor
public final class MacSpotlightKeyboard: SpotlightKeyboard {
    private let source = CGEventSource(stateID: .privateState)
    private var commandReleaseEvent: CGEvent?
    private let makeEvent: (CGEventSource, CGKeyCode, Bool) -> CGEvent?
    private let postCommandEvent: (CGEvent) -> Void

    public convenience init() {
        self.init(
            makeEvent: { CGEvent(keyboardEventSource: $0, virtualKey: $1, keyDown: $2) },
            postCommandEvent: { $0.post(tap: .cgSessionEventTap) }
        )
    }

    // Keep native allocation failures testable without posting keyboard input.
    init(
        makeEvent: @escaping (CGEventSource, CGKeyCode, Bool) -> CGEvent?,
        postCommandEvent: @escaping (CGEvent) -> Void
    ) {
        self.makeEvent = makeEvent
        self.postCommandEvent = postCommandEvent
    }

    public var hasPermission: Bool {
        AXIsProcessTrusted() && CGPreflightPostEventAccess()
    }

    public var physicalModifiersReleased: Bool {
        let modifiers: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn]
        return CGEventSource.flagsState(.hidSystemState).intersection(modifiers).isEmpty
    }

    public var spotlightHasFocus: Bool { focusedSpotlightPID() != nil }

    public func holdCommand() throws {
        guard commandReleaseEvent == nil else { return }
        // Reserve cleanup before posting any key-down; release must not allocate.
        let release = try key(CGKeyCode(kVK_Command), down: false, flags: [])
        let event = try key(CGKeyCode(kVK_Command), down: true, flags: .maskCommand)
        commandReleaseEvent = release
        postCommandEvent(event)
    }

    public func pressSpace() throws {
        let down = try key(CGKeyCode(kVK_Space), down: true, flags: .maskCommand)
        let up = try key(CGKeyCode(kVK_Space), down: false, flags: .maskCommand)
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }

    public func pressFourIfSpotlightFocused() throws {
        guard hasPermission else { throw HistoryActionError.permissionMissing }
        let down = try key(CGKeyCode(kVK_ANSI_4), down: true, flags: .maskCommand)
        let up = try key(CGKeyCode(kVK_ANSI_4), down: false, flags: .maskCommand)
        guard let pid = focusedSpotlightPID() else { throw HistoryActionError.spotlightNotFocused }
        // Address Spotlight itself: a focus switch must never deliver ⌘4 to another app.
        down.postToPid(pid)
        up.postToPid(pid)
    }

    public func releaseCommand() {
        guard let event = commandReleaseEvent else { return }
        postCommandEvent(event)
        commandReleaseEvent = nil
    }

    private func key(_ code: CGKeyCode, down: Bool, flags: CGEventFlags) throws -> CGEvent {
        guard let source,
              let event = makeEvent(source, code, down)
        else { throw HistoryActionError.eventCreationFailed }
        event.flags = flags
        return event
    }

    private func focusedSpotlightPID() -> pid_t? {
        guard AXIsProcessTrusted() else { return nil }
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.05)
        var application: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedApplicationAttribute as CFString, &application) == .success,
              let application, CFGetTypeID(application) == AXUIElementGetTypeID()
        else { return nil }
        let app = unsafeDowncast(application, to: AXUIElement.self)
        var pid: pid_t = 0
        guard AXUIElementGetPid(app, &pid) == .success,
              let runningApp = NSRunningApplication(processIdentifier: pid),
              isSystemSpotlight(runningApp)
        else { return nil }
        AXUIElementSetMessagingTimeout(app, 0.05)
        var element: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &element) == .success,
              let element, CFGetTypeID(element) == AXUIElementGetTypeID()
        else { return nil }
        if runningApp.bundleIdentifier == "com.apple.campo" {
            // Campo also hosts Siri. Only recognize the Spotlight search field,
            // not an unrelated Siri conversation. Never read the field's value.
            let focusedElement = unsafeDowncast(element, to: AXUIElement.self)
            var identifier: CFTypeRef?
            guard AXUIElementCopyAttributeValue(focusedElement, kAXIdentifierAttribute as CFString, &identifier) == .success,
                  identifier as? String == "SpotlightSearchField"
            else { return nil }
        }
        return pid
    }

    private func isSystemSpotlight(_ app: NSRunningApplication) -> Bool {
        // macOS 27 hosts Spotlight in Siri AI (Campo). Keep the legacy host for
        // Macs where that system feature is disabled; never match by display name.
        switch (app.bundleIdentifier, app.bundleURL?.path) {
        case ("com.apple.Spotlight", "/System/Library/CoreServices/Spotlight.app"),
             ("com.apple.campo", "/System/Applications/Siri AI.app"):
            true
        default:
            false
        }
    }
}
