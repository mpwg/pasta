// SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// No clipboard contents pass through this interface.
@MainActor
public protocol SpotlightKeyboard: AnyObject {
    var hasPermission: Bool { get }
    var physicalModifiersReleased: Bool { get }
    var spotlightHasFocus: Bool { get }
    func holdCommand() throws
    func pressSpace() throws
    func pressFourIfSpotlightFocused() throws
    func releaseCommand()
}

public enum HistoryActionError: Error, Equatable, LocalizedError {
    case permissionMissing
    case modifiersHeld
    case spotlightNotFocused
    case eventCreationFailed

    public var errorDescription: String? {
        String(localized: message)
    }

    var message: LocalizedStringResource {
        switch self {
        case .permissionMissing:
            LocalizedStringResource(
                "Pasta needs Accessibility permission. Allow Pasta in System Settings → Privacy & Security → Accessibility.",
                bundle: .atURL(Bundle.module.bundleURL)
            )
        case .modifiersHeld:
            LocalizedStringResource(
                "Please release all modifier keys and try again.",
                bundle: .atURL(Bundle.module.bundleURL)
            )
        case .spotlightNotFocused:
            LocalizedStringResource(
                "Spotlight did not confirm keyboard focus. No 4 key was sent. Check that ⌘Space opens Spotlight.",
                bundle: .atURL(Bundle.module.bundleURL)
            )
        case .eventCreationFailed:
            LocalizedStringResource(
                "The key sequence could not be created. Please try again.",
                bundle: .atURL(Bundle.module.bundleURL)
            )
        }
    }
}

public enum HistoryActionResult: Equatable {
    case sent
    case ignoredWhileRunning
}

/// Serializes the whole chord; even an error/cancellation releases synthetic ⌘.
@MainActor
public final class ClipboardHistoryAction {
    public private(set) var isRunning = false
    private let keyboard: any SpotlightKeyboard
    private let now: () -> Duration
    private let pause: () async throws -> Void

    public init(keyboard: any SpotlightKeyboard) {
        let clock = ContinuousClock()
        let origin = clock.now
        self.keyboard = keyboard
        now = { origin.duration(to: clock.now) }
        pause = { try await Task.sleep(for: .milliseconds(20)) }
    }

    // Inject time in tests so timeouts and cancellation have deterministic evidence.
    init(
        keyboard: any SpotlightKeyboard,
        now: @escaping () -> Duration,
        pause: @escaping () async throws -> Void
    ) {
        self.keyboard = keyboard
        self.now = now
        self.pause = pause
    }

    @discardableResult
    public func open() async throws -> HistoryActionResult {
        guard !isRunning else { return .ignoredWhileRunning }
        isRunning = true
        defer { isRunning = false }
        guard keyboard.hasPermission else { throw HistoryActionError.permissionMissing }

        let releaseDeadline = now() + .seconds(1)
        while !keyboard.physicalModifiersReleased {
            guard now() < releaseDeadline else { throw HistoryActionError.modifiersHeld }
            try await pause()
        }
        try Task.checkCancellation()
        guard keyboard.hasPermission else { throw HistoryActionError.permissionMissing }

        // Install cleanup before key-down, including failures in later events.
        defer { keyboard.releaseCommand() }
        try keyboard.holdCommand()
        if !keyboard.spotlightHasFocus {
            let focusDeadline = now() + .seconds(1)
            try keyboard.pressSpace()
            while true {
                try Task.checkCancellation()
                guard keyboard.hasPermission else { throw HistoryActionError.permissionMissing }
                let focused = keyboard.spotlightHasFocus
                guard now() < focusDeadline else { throw HistoryActionError.spotlightNotFocused }
                if focused { break }
                try await pause()
            }
        }
        try Task.checkCancellation()
        try keyboard.pressFourIfSpotlightFocused()
        return .sent
    }
}
