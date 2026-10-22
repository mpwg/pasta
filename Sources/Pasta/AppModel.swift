import Foundation
import KeyboardShortcuts
import Observation
import PastaCore
import ServiceManagement

extension KeyboardShortcuts.Name {
    static let openClipboardHistory = Self(
        "openClipboardHistory",
        initial: .init(.v, modifiers: [.command, .shift])
    )
}

@MainActor @Observable
final class AppModel {
    let showsSettingsOnLaunch: Bool
    private(set) var permissionGranted = false
    private(set) var startsAtLogin = false
    private(set) var loginNeedsApproval = false
    private(set) var isOpening = false
    private(set) var errorMessage: String?
    private(set) var shortcutDescription = "⌘⇧V"

    @ObservationIgnored private let keyboard: MacSpotlightKeyboard
    @ObservationIgnored private let action: ClipboardHistoryAction
    @ObservationIgnored private var openingTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false

    init() {
        let keyboard = MacSpotlightKeyboard()
        self.keyboard = keyboard
        action = ClipboardHistoryAction(keyboard: keyboard)
        showsSettingsOnLaunch = !UserDefaults.standard.bool(forKey: "hasShownSettings") || !keyboard.hasPermission
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        refresh()
        KeyboardShortcuts.onKeyUp(for: .openClipboardHistory) { [weak self] in
            self?.openHistory()
        }
    }

    func markSettingsShown() {
        UserDefaults.standard.set(true, forKey: "hasShownSettings")
        refresh()
    }

    func refresh() {
        permissionGranted = keyboard.hasPermission
        let status = SMAppService.mainApp.status
        startsAtLogin = status == .enabled || status == .requiresApproval
        loginNeedsApproval = status == .requiresApproval
        shortcutDescription = KeyboardShortcuts.getShortcut(for: .openClipboardHistory)?.description ?? "Kein Shortcut"
    }

    func openHistory() {
        guard !isOpening else { return }
        isOpening = true
        errorMessage = nil
        // Return focus to the previous app when testing from our own window.
        MacApplication.hideIfActive()
        openingTask = Task { [weak self] in
            guard let self else { return }
            defer {
                isOpening = false
                openingTask = nil
            }
            do {
                try await action.open()
            } catch is CancellationError {
                // Closing the app must not open an error window.
            } catch {
                errorMessage = error.localizedDescription
                refresh()
            }
        }
    }

    func requestPermission() {
        MacApplication.requestAccessibilityPermission()
        refresh()
    }

    func setStartsAtLogin(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Der Start beim Anmelden konnte nicht geändert werden: \(error.localizedDescription)"
        }
        refresh()
    }

    func openLoginSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func resetShortcut() {
        KeyboardShortcuts.reset(.openClipboardHistory)
        refresh()
    }

    func shutdown() {
        openingTask?.cancel()
        keyboard.releaseCommand()
    }
}
