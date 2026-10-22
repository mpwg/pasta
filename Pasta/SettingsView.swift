// SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
// SPDX-License-Identifier: GPL-3.0-or-later

import KeyboardShortcuts
import SwiftUI

struct PastaMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Clipboard History") { model.openHistory() }
            .disabled(model.isOpening)
            .globalKeyboardShortcut(.openClipboardHistory)
        Divider()
        Button("Settings …") {
            openWindow(id: "settings")
            MacApplication.activate()
        }
            .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit Pasta") { MacApplication.quit() }
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
                Image(nsImage: MacApplication.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pasta").font(.largeTitle.bold())
                    Text("Your clipboard. One shortcut.")
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

                    Text("Pasta opens the macOS clipboard history. Your copied content stays with macOS.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }

            Divider()
            HStack {
                Text(model.permissionGranted ? LocalizedStringResource("Ready") : LocalizedStringResource("Permission Required"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit Pasta") { MacApplication.quit() }
                Button("Open Clipboard") { model.openHistory() }
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
                    Text("Open Clipboard")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .openClipboardHistory) { _ in model.refresh() }
                        .shortcutValidation(MacApplication.validateShortcut)
                        .accessibilityLabel("Clipboard History Shortcut")
                        .accessibilityIdentifier("shortcutRecorder")
                }
                HStack {
                    Text("Click the field and press your shortcut.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset") { model.resetShortcut() }
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
                    model.permissionGranted
                        ? LocalizedStringResource("Accessibility Access Allowed")
                        : LocalizedStringResource("Allow Accessibility Access"),
                    systemImage: model.permissionGranted ? "checkmark.circle.fill" : "lock"
                )
                .foregroundStyle(model.permissionGranted ? Color.green : Color.primary)
                .accessibilityIdentifier("permissionStatus")

                Text("Pasta needs this permission to press ⌘Space and then ⌘4 for you.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !model.permissionGranted {
                    Button("Grant Permission …") { model.requestPermission() }
                    Text("Enable Pasta in System Settings. If macOS then asks you to restart the app, quit and reopen Pasta.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        } label: {
            Label("Permission", systemImage: "hand.raised")
        }
    }
}

private struct LoginSettings: View {
    let model: AppModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Launch at Login", isOn: Binding(
                    get: { model.startsAtLogin },
                    set: { model.setStartsAtLogin($0) }
                ))
                .accessibilityIdentifier("launchAtLogin")
                if model.loginNeedsApproval {
                    Text("Please approve Pasta in macOS Login Items.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Login Items …") { model.openLoginSettings() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        } label: {
            Label("Launch", systemImage: "power")
        }
    }
}
