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

## Bauen und prüfen

Für die App wird **Xcode 27 oder neuer** benötigt. Einmal starten und die Einrichtung abschließen. Falls Xcode nicht als aktive Entwicklerumgebung eingestellt ist, kann `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` vorangestellt werden. Die Command Line Tools allein enthalten die benötigten SwiftUI-Makro-Erweiterungen nicht. Für die isolierten Kerntests und `PastaProbe` genügen die Command Line Tools mit Swift 6.2+ und macOS-27-SDK.

```sh
./scripts/test.sh
./scripts/build-app.sh
open dist/Pasta.app
swift run --build-system native PastaProbe
swift run --build-system native PastaProbe --open
```

Das Build-Skript erstellt `dist/Pasta.app` mit einer lokalen Ad-hoc-Signatur. Für die Nutzung die App nach `/Applications` kopieren und **von dort starten**, bevor Rechte erteilt oder Autostart aktiviert werden. Die lokale Signatur ist keine Developer-ID-Signatur und keine Notarisierung. Veröffentlichung ist nicht Teil dieses Arbeitspakets. Ein neuer Build kann eine erneute Rechtevergabe und Autostart-Registrierung erfordern.

Pasta zeigt beim ersten Start die Einstellungen. Klicke auf **Berechtigung erteilen …** und aktiviere Pasta in den Bedienungshilfen. Danach lässt sich die Historie mit dem Shortcut oder über das Menüleistensymbol öffnen. Im Shortcut-Feld kann eine andere Kombination aufgezeichnet, gelöscht oder auf ⌘⇧V zurückgesetzt werden. ⌘Leertaste und ⌘4 sind für die interne Sequenz reserviert. **Beim Anmelden starten** ist standardmäßig ausgeschaltet und verwendet die Anmeldeobjekte von macOS.

`PastaProbe` zeigt ohne `--open` nur Berechtigung und Fokusstatus an. Mit `--open` führt es die echte Tastensequenz aus. Es muss im angemeldeten Desktop laufen und benötigt die entsprechenden Rechte des startenden Terminals. Es liest keine Zwischenablageinhalte.

Unter macOS 27 kann Spotlight durch den Systemprozess `com.apple.campo` in `/System/Applications/Siri AI.app` bereitgestellt werden. Pasta erkennt dort zusätzlich die Kennung `SpotlightSearchField`, um Spotlight von anderen Siri-Oberflächen zu unterscheiden. Bei deaktivierter Campo-Systemfunktion wird der klassische Spotlight-Systemprozess erkannt. Diese Betriebssystemdetails müssen bei späteren macOS-Versionen erneut geprüft werden.

Grundlage: [Apple: Zwischenablagehistorie in Spotlight durchsuchen](https://support.apple.com/en-za/guide/mac-help/mchl40d5b86b/mac).
