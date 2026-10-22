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

@Suite(.timeLimit(.minutes(1))) @MainActor
struct ClipboardHistoryActionTests {
    @Test(arguments: [false, true])
    func `Command stays held, and already focused Spotlight is not toggled`(alreadyFocused: Bool) async throws {
        let keyboard = Keyboard()
        keyboard.spotlightHasFocus = alreadyFocused
        #expect(try await Time().action(keyboard).open() == .sent)
        let expected = alreadyFocused
            ? ["commandDown", "four", "commandUp"]
            : ["commandDown", "space", "four", "commandUp"]
        #expect(keyboard.events == expected)
    }

    @Test func `Missing permission sends no keyboard events`() async {
        let keyboard = Keyboard()
        keyboard.hasPermission = false
        await #expect(throws: HistoryActionError.permissionMissing) { try await Time().action(keyboard).open() }
        #expect(keyboard.events.isEmpty)
    }

    @Test func `Missing focus times out after one second and releases command`() async {
        let keyboard = Keyboard()
        keyboard.focusesAfterSpace = false
        let time = Time()
        let action = time.action(keyboard)
        await #expect(throws: HistoryActionError.spotlightNotFocused) { try await action.open() }
        #expect(time.value == .seconds(1))
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
        #expect(!action.isRunning)
    }

    @Test func `Held physical modifiers time out without sending events`() async {
        let keyboard = Keyboard()
        keyboard.physicalModifiersReleased = false
        await #expect(throws: HistoryActionError.modifiersHeld) { try await Time().action(keyboard).open() }
        #expect(keyboard.events.isEmpty)
    }

    @Test func `Event creation failure releases command`() async {
        let keyboard = Keyboard()
        keyboard.failFour = true
        await #expect(throws: HistoryActionError.eventCreationFailed) { try await Time().action(keyboard).open() }
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
    }

    @Test func `Revoked permission during focus wait prevents four`() async {
        let keyboard = Keyboard()
        keyboard.focusesAfterSpace = false
        let action = ClipboardHistoryAction(keyboard: keyboard, now: { .zero }, pause: {
            keyboard.hasPermission = false
        })
        await #expect(throws: HistoryActionError.permissionMissing) { try await action.open() }
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
        #expect(!action.isRunning)
    }

    @Test func `Cancellation during focus wait releases command`() async {
        let keyboard = Keyboard()
        keyboard.focusesAfterSpace = false
        let action = ClipboardHistoryAction(keyboard: keyboard, now: { .zero }, pause: {
            throw CancellationError()
        })
        await #expect(throws: CancellationError.self) { try await action.open() }
        #expect(keyboard.events == ["commandDown", "space", "commandUp"])
        #expect(!action.isRunning)
    }

    @Test func `Physical modifiers must be released before the chord starts`() async throws {
        let keyboard = Keyboard()
        keyboard.physicalModifiersReleased = false
        let action = ClipboardHistoryAction(keyboard: keyboard, now: { .zero }, pause: {
            #expect(keyboard.events.isEmpty)
            keyboard.physicalModifiersReleased = true
        })
        try await action.open()
        #expect(keyboard.events == ["commandDown", "space", "four", "commandUp"])
    }

    @Test func `A second call is ignored while the first is suspended`() async throws {
        let keyboard = Keyboard()
        keyboard.physicalModifiersReleased = false
        let entered = AsyncStream<Void>.makeStream()
        let resumed = AsyncStream<Void>.makeStream()
        defer {
            entered.continuation.finish()
            resumed.continuation.finish()
        }
        let action = ClipboardHistoryAction(keyboard: keyboard, now: { .zero }, pause: {
            entered.continuation.yield(())
            for await _ in resumed.stream { break }
        })
        let first = Task { try await action.open() }
        for await _ in entered.stream { break }
        #expect(try await action.open() == .ignoredWhileRunning)
        #expect(keyboard.events.isEmpty)
        keyboard.physicalModifiersReleased = true
        resumed.continuation.yield(())
        #expect(try await first.value == .sent)
        #expect(keyboard.events == ["commandDown", "space", "four", "commandUp"])
    }
}
