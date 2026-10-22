import SwiftUI

@main
struct PastaApp: App {
    @State private var model: AppModel

    init() {
        // SDK 27: initialize @State only here, without a declaration default.
        model = AppModel()
    }

    var body: some Scene {
        MenuBarExtra {
            PastaMenu(model: model)
        } label: {
            PastaStatusLabel(model: model)
        }
        .menuBarExtraStyle(.menu)

        Window("Pasta – Einstellungen", id: "settings") {
            SettingsView(model: model)
                .onAppear { model.markSettingsShown() }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultLaunchBehavior(model.showsSettingsOnLaunch ? .presented : .suppressed)
        .restorationBehavior(.disabled)
    }
}

private struct PastaStatusLabel: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Label("Pasta", systemImage: "clipboard")
            .onAppear { model.start() }
            .onChange(of: model.errorMessage) { _, error in
                guard error != nil else { return }
                openWindow(id: "settings")
                MacApplication.activate()
            }
            .onReceive(NotificationCenter.default.publisher(for: MacApplication.willTerminateNotification)) { _ in
                model.shutdown()
            }
    }
}
