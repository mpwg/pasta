import XCTest

// Native macOS UI automation remains XCTest; the core uses Swift Testing.
nonisolated final class PastaUITests: XCTestCase {
    @MainActor
    func testSettingsExposeShortcutPermissionsAndLoginOption() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--show-settings"]
        app.launch()
        defer { app.terminate() }

        let window = app.windows["Pasta – Einstellungen"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.descendants(matching: .any)["shortcutRecorder"].exists)
        XCTAssertTrue(window.buttons["Zurücksetzen"].exists)
        XCTAssertTrue(window.descendants(matching: .any)["permissionStatus"].exists)
        XCTAssertTrue(window.descendants(matching: .any)["launchAtLogin"].exists)
    }
}
