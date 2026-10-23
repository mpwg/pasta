// SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
// SPDX-License-Identifier: GPL-3.0-or-later

import ApplicationServices
import Carbon.HIToolbox
import Testing
@testable import PastaCore

@Suite @MainActor
struct MacSpotlightKeyboardTests {
    @Test(arguments: [false, true])
    func `Either command allocation failure posts nothing`(failDown: Bool) {
        var posted: [CGEvent] = []
        let keyboard = MacSpotlightKeyboard(makeEvent: { source, code, down in
            guard down != failDown else { return nil }
            return CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down)
        }, postCommandEvent: { posted.append($0) })

        #expect(throws: HistoryActionError.eventCreationFailed) { try keyboard.holdCommand() }
        keyboard.releaseCommand()
        #expect(posted.isEmpty)
    }

    @Test func `Cleanup uses a reserved event and repeated release is harmless`() throws {
        var allocations = 0
        var posted: [CGEvent] = []
        let keyboard = MacSpotlightKeyboard(makeEvent: { source, code, down in
            allocations += 1
            return CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down)
        }, postCommandEvent: { posted.append($0) })

        keyboard.releaseCommand()
        #expect(posted.isEmpty)
        try keyboard.holdCommand()
        try keyboard.holdCommand()
        #expect(allocations == 2)
        #expect(posted.count == 1)
        keyboard.releaseCommand()
        keyboard.releaseCommand()
        #expect(allocations == 2)
        // Core Graphics represents modifier transitions as flagsChanged events.
        #expect(posted.map(\.type) == [.flagsChanged, .flagsChanged])
        #expect(posted.first?.flags.contains(.maskCommand) == true)
        #expect(posted.last?.flags.isEmpty == true)
        #expect(posted.allSatisfy { $0.getIntegerValueField(.keyboardEventKeycode) == Int64(kVK_Command) })

        try keyboard.holdCommand()
        keyboard.releaseCommand()
        #expect(posted.count == 4)
        #expect(posted[2].flags.contains(.maskCommand))
        #expect(posted[3].flags.isEmpty)
    }
}
