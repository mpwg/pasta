import AppKit
import PastaCore

@main
struct PastaProbe {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = ProbeDelegate()
        app.setActivationPolicy(.prohibited)
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
private final class ProbeDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await runProbe() }
    }

    private func runProbe() async {
        let keyboard = MacSpotlightKeyboard()
        print("Berechtigung: \(keyboard.hasPermission), Spotlight-Fokus: \(keyboard.spotlightHasFocus)")
        guard CommandLine.arguments.contains("--open") else {
            print("Mit --open wird die Tastensequenz einmal ausgeführt. Keine Zwischenablageinhalte werden gelesen.")
            NSApplication.shared.terminate(nil)
            return
        }
        do {
            let result = try await ClipboardHistoryAction(keyboard: keyboard).open()
            print("Ergebnis: \(result); Spotlight-Fokus danach: \(keyboard.spotlightHasFocus)")
            NSApplication.shared.terminate(nil)
        } catch {
            print("Abbruch: \(error.localizedDescription)")
            exit(1)
        }
    }
}
