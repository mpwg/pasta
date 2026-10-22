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
        switch self {
        case .permissionMissing:
            "Pasta benötigt die Bedienungshilfen-Berechtigung. Erlaube Pasta unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen."
        case .modifiersHeld:
            "Bitte lasse alle Sondertasten los und versuche es erneut."
        case .spotlightNotFocused:
            "Spotlight hat den Tastaturfokus nicht bestätigt. Es wurde keine 4 gesendet. Prüfe, ob ⌘Leertaste Spotlight öffnet."
        case .eventCreationFailed:
            "Die Tastensequenz konnte nicht erstellt werden. Bitte versuche es erneut."
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
