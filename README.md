# Pasta

Eine kleine native Menüleisten-App für macOS 27+. Ein frei wählbarer globaler Shortcut (standardmäßig **⌘⇧V**) öffnet die integrierte Zwischenablagehistorie von macOS.

Pasta hält synthetisch ⌘ gedrückt, drückt und löst die Leertaste, wartet auf den bestätigten Spotlight-Fokus und drückt anschließend 4. Zum Schluss wird ⌘ losgelassen, auch bei einem Fehler. Bei bereits fokussiertem Spotlight entfällt die Leertaste. Der Start erfolgt beim Loslassen des eigenen Shortcuts; gehaltene physische Sondertasten werden bis zu einer Sekunde abgewartet. Weitere Aufrufe während der Sequenz werden ignoriert.

## Voraussetzungen

- macOS 27 oder neuer.
- **⌘Leertaste** öffnet Spotlight. Die Zwischenablagehistorie muss in macOS aktiviert sein.
- Bedienungshilfen-Berechtigung für Pasta unter **Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen**.
- Andere Programme können ⌘⇧V ebenfalls verwenden. Wähle bei Bedarf einen anderen Pasta-Shortcut.

Pasta liest oder speichert keine Zwischenablageinhalte, überwacht keine Kopiervorgänge und benötigt kein Netzwerk zur Laufzeit. Sie prüft lediglich den Systemprozess und den Tastaturfokus. ⌘4 wird ausschließlich an den bestätigten Spotlight-Prozess adressiert. Kann der Fokus innerhalb einer Sekunde nicht bestätigt werden, wird abgebrochen.

## Entwicklungsstand

Menüleiste, Einstellungen und App-Lebenszyklus sind mit SwiftUI implementiert, ohne Mac Catalyst, UIKit oder eigene AppKit-Fenster/-Delegates. Kleine AppKit-Aufrufe werden für macOS-Dienste wie Aktivieren, Verbergen, Beenden und Öffnen der Systemeinstellungen verwendet. Der native Tastaturkern bleibt als eigenes Swift-Paket unabhängig von der Oberfläche prüfbar. Die aktuelle Abnahme mit Belegen und offenen Prüfungen steht in [docs/abnahme.md](docs/abnahme.md).

## In Xcode bauen und prüfen

Benötigt wird **Xcode 27 oder neuer**. Einmal starten und die Einrichtung abschließen. Die Command Line Tools allein enthalten die benötigten SwiftUI-Makro-Erweiterungen nicht.

1. **Pasta.xcodeproj** öffnen.
2. Das Scheme **Pasta** und das Ziel **My Mac** wählen.
3. Mit **⌘R** die native App bauen und starten.
4. Mit **⌘U** die Kerntests und den nativen Oberflächentest ausführen.

Es gibt keine manuellen Build-Skripte oder Shell-Build-Phasen. Xcode verwaltet das App-Bundle und die Paketabhängigkeiten: das lokale Paket `Packages/PastaCore` und KeyboardShortcuts, fest auf Version 3.1.0 gesetzt. `PastaTests` enthält Swift-Testing-Tests für den Kern im regulären App-Testhost; die Tests selbst bedienen keine Oberfläche und senden keine echten Tastendrücke. `PastaUITests` verwendet das für native Oberflächenautomation erforderliche XCTest. Der Startparameter `--show-settings` öffnet die Einstellungen unabhängig vom bisherigen Einrichtungsstand, ohne Rechte oder Nutzereinstellungen zu umgehen.

Das Projekt verwendet eine lokale Ad-hoc-Signatur. Für die dauerhafte Nutzung die gebaute **Pasta.app** aus Xcodes Produktgruppe nach `/Applications` kopieren und **von dort starten**, bevor Rechte erteilt oder Autostart aktiviert werden. Die lokale Signatur ist keine Developer-ID-Signatur und keine Notarisierung. Veröffentlichung ist nicht Teil dieses Arbeitspakets. Ein neuer Build kann eine erneute Rechtevergabe und Autostart-Registrierung erfordern.

Pasta zeigt beim ersten Start die Einstellungen. Klicke auf **Berechtigung erteilen …** und aktiviere Pasta in den Bedienungshilfen. Danach lässt sich die Historie mit dem Shortcut oder über das Menüleistensymbol öffnen. Im Shortcut-Feld kann eine andere Kombination aufgezeichnet, gelöscht oder auf ⌘⇧V zurückgesetzt werden. ⌘Leertaste und ⌘4 sind für die interne Sequenz reserviert. **Beim Anmelden starten** ist standardmäßig ausgeschaltet und verwendet die Anmeldeobjekte von macOS.

Unter macOS 27 kann Spotlight durch den Systemprozess `com.apple.campo` in `/System/Applications/Siri AI.app` bereitgestellt werden. Pasta erkennt dort zusätzlich die Kennung `SpotlightSearchField`, um Spotlight von anderen Siri-Oberflächen zu unterscheiden. Bei deaktivierter Campo-Systemfunktion wird der klassische Spotlight-Systemprozess erkannt. Diese Betriebssystemdetails müssen bei späteren macOS-Versionen erneut geprüft werden.

Grundlage: [Apple: Zwischenablagehistorie in Spotlight durchsuchen](https://support.apple.com/en-za/guide/mac-help/mchl40d5b86b/mac).
