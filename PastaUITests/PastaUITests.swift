// SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

// Native macOS UI automation remains XCTest; the core uses Swift Testing.
nonisolated final class PastaUITests: XCTestCase {
    @MainActor
    func testGermanSettings() {
        checkSettings(
            language: "de", title: "Pasta – Einstellungen", reset: "Zurücksetzen",
            tagline: "Deine Zwischenablage. Ein Shortcut.",
            permissionLabels: ["Bedienungshilfen erlaubt", "Bedienungshilfen erlauben"],
            login: "Beim Anmelden starten"
        )
    }

    @MainActor
    func testEnglishSettings() {
        checkSettings(
            language: "en", title: "Pasta – Settings", reset: "Reset",
            tagline: "Your clipboard. One shortcut.",
            permissionLabels: ["Accessibility Access Allowed", "Allow Accessibility Access"],
            login: "Launch at Login"
        )
    }

    @MainActor
    func testUnsupportedLanguageFallsBackToEnglish() {
        checkSettings(
            language: "fr", title: "Pasta – Settings", reset: "Reset",
            tagline: "Your clipboard. One shortcut.",
            permissionLabels: ["Accessibility Access Allowed", "Allow Accessibility Access"],
            login: "Launch at Login"
        )
    }

    @MainActor
    private func checkSettings(
        language: String, title: String, reset: String, tagline: String,
        permissionLabels: [String], login: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = ["--show-settings", "-AppleLanguages", "(\(language))", "-AppleLocale", language]
        app.launch()
        defer { app.terminate() }

        let window = app.windows[title]
        if !window.waitForExistence(timeout: 3) {
            app.menuBars.statusItems.firstMatch.click()
            app.menuItems[language == "de" ? "Einstellungen …" : "Settings …"].click()
        }
        guard window.waitForExistence(timeout: 5) else {
            XCTFail("Settings window missing: \(app.debugDescription)")
            return
        }
        XCTAssertTrue(window.descendants(matching: .any)["shortcutRecorder"].exists)
        XCTAssertTrue(window.buttons[reset].exists)
        XCTAssertTrue(window.staticTexts[tagline].exists)
        let permissionStatus = window.descendants(matching: .any)["permissionStatus"]
        XCTAssertTrue(permissionStatus.exists)
        XCTAssertTrue(permissionLabels.contains { window.staticTexts[$0].exists })
        let readinessLabels = language == "de" ? ["Bereit", "Berechtigung fehlt"] : ["Ready", "Permission Required"]
        XCTAssertTrue(readinessLabels.contains { window.staticTexts[$0].exists })
        let launchAtLogin = window.descendants(matching: .any)["launchAtLogin"]
        XCTAssertTrue(launchAtLogin.exists)
        XCTAssertEqual(launchAtLogin.label, login)
    }
}
