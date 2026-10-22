import KeyboardShortcuts
import SwiftUI

struct PastaMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Zwischenablagehistorie öffnen") { model.openHistory() }
            .disabled(model.isOpening)
        Text(model.shortcutDescription)
        Divider()
        Button("Einstellungen …") {
            openWindow(id: "settings")
            MacApplication.activate()
        }
            .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Pasta beenden") { MacApplication.quit() }
            .keyboardShortcut("q", modifiers: .command)
        .onAppear { model.refresh() }
    }
}

struct SettingsView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "clipboard")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pasta").font(.largeTitle.bold())
                    Text("Deine Zwischenablage. Ein Shortcut.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ShortcutSettings(model: model)
                    PermissionSettings(model: model)
                    LoginSettings(model: model)

                    if let error = model.errorMessage {
                        Label {
                            Text(error).fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                        }
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("actionError")
                    }

                    Text("Pasta öffnet die Zwischenablagehistorie von macOS. Deine kopierten Inhalte bleiben bei macOS.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }

            Divider()
            HStack {
                Text(model.permissionGranted ? "Bereit" : "Berechtigung fehlt")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Zwischenablage öffnen") { model.openHistory() }
                    .disabled(!model.permissionGranted || model.isOpening)
            }
            .padding(16)
        }
        .frame(width: 520, height: 590)
        .background(.background)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }
}

private struct ShortcutSettings: View {
    let model: AppModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Zwischenablage öffnen")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .openClipboardHistory) { _ in model.refresh() }
                        .shortcutValidation { shortcut in
                            if shortcut == .init(.space, modifiers: .command)
                                || shortcut == .init(.four, modifiers: .command) {
                                return .disallow(reason: "Diese Tastenkombination wird zum Öffnen der macOS-Zwischenablage benötigt.")
                            }
                            return .allow
                        }
                        .accessibilityLabel("Shortcut für die Zwischenablagehistorie")
                        .accessibilityIdentifier("shortcutRecorder")
                }
                HStack {
                    Text("Klicke in das Feld und drücke deinen Shortcut.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Zurücksetzen") { model.resetShortcut() }
                        .font(.footnote)
                }
            }
            .padding(8)
        } label: {
            Label("Shortcut", systemImage: "keyboard")
        }
    }
}

private struct PermissionSettings: View {
    let model: AppModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    model.permissionGranted ? "Bedienungshilfen erlaubt" : "Bedienungshilfen erlauben",
                    systemImage: model.permissionGranted ? "checkmark.circle.fill" : "lock"
                )
                .foregroundStyle(model.permissionGranted ? Color.green : Color.primary)
                .accessibilityIdentifier("permissionStatus")

                Text("Pasta benötigt diese Berechtigung, um ⌘Leertaste und anschließend ⌘4 für dich zu drücken.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !model.permissionGranted {
                    Button("Berechtigung erteilen …") { model.requestPermission() }
                    Text("Aktiviere Pasta in den Systemeinstellungen. Falls macOS danach einen Neustart der App verlangt, beende und öffne Pasta erneut.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        } label: {
            Label("Berechtigung", systemImage: "hand.raised")
        }
    }
}

private struct LoginSettings: View {
    let model: AppModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Beim Anmelden starten", isOn: Binding(
                    get: { model.startsAtLogin },
                    set: { model.setStartsAtLogin($0) }
                ))
                .accessibilityIdentifier("launchAtLogin")
                if model.loginNeedsApproval {
                    Text("Bitte bestätige Pasta noch in den Anmeldeobjekten von macOS.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Anmeldeobjekte öffnen …") { model.openLoginSettings() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        } label: {
            Label("Start", systemImage: "power")
        }
    }
}
