import Testing
@testable import PastaCore

@MainActor
private final class Keyboard: SpotlightKeyboard {
    var hasPermission = true
    var physicalModifiersReleased = true
    var spotlightHasFocus = false
    var focusesAfterSpace = true
    var events: [String] = []
    var failFour = false
    func holdCommand() throws { events.append("commandDown") }
    func pressSpace() throws {
        events.append("space")
        spotlightHasFocus = focusesAfterSpace
    }
    func pressFourIfSpotlightFocused() throws {
        guard spotlightHasFocus else { throw HistoryActionError.spotlightNotFocused }
        if failFour { throw HistoryActionError.eventCreationFailed }
        events.append("four")
    }
    func releaseCommand() { events.append("commandUp") }
}

@MainActor
private final class Time {
    var value: Duration = .zero
    func pause() async throws { value += .milliseconds(20); await Task.yield() }
    func action(_ keyboard: Keyboard) -> ClipboardHistoryAction {
        ClipboardHistoryAction(keyboard: keyboard, now: { self.value }, pause: { try await self.pause() })
    }
}

@Suite @MainActor
struct ClipboardHistoryActionTests {
    @Test func oneContinuousChord() async throws {
        let keyboard = Keyboard()
        #expect(try await Time().action(keyboard).open() == .sent)
        #expect(keyboard.events == ["commandDown", "space", "four", "commandUp"])
    }

    @Test func alreadyOpenDoesNotToggleSpotlight() async throws {
        let keyboard = Keyboard()
        keyboard.spotlightHasFocus = true
        try await Time().action(keyboard).open()
        #expect(keyboard.events == ["commandDown", "four", "commandUp"])
    }

    @Test func noPermissionSendsNothing() async {
        let keyboard = Keyboard()
        keyboard.hasPermission = false
        await #expect(throws: HistoryActionError.permissionMissing) { try await Time().action(keyboard).open() }
        #expect(keyboard.events.isEmpty)
    }

    @Test func missingFocusTimesOutAndReleasesCommand() async {
        let keyboard = Keyboard()
        keyboard.focusesAfterSpace = false
        let time = Time()
        let action = time.action(keyboard)
        await #expect(throws: HistoryActionError.spotlightNotFocused) { try await action.open() }
        #expect(time.value == .seconds(1))
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
        #expect(!action.isRunning)
    }

    @Test func heldPhysicalModifierSendsNothing() async {
        let keyboard = Keyboard()
        keyboard.physicalModifiersReleased = false
        await #expect(throws: HistoryActionError.modifiersHeld) { try await Time().action(keyboard).open() }
        #expect(keyboard.events.isEmpty)
    }

    @Test func eventFailureReleasesCommand() async {
        let keyboard = Keyboard()
        keyboard.failFour = true
        await #expect(throws: HistoryActionError.eventCreationFailed) { try await Time().action(keyboard).open() }
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
    }
}
