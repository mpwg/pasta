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

Der native Kern und ein Machbarkeitstest sind implementiert. Menüleiste und Einstellungen folgen nach dem erfolgreichen Systemtest. Die aktuelle Abnahme mit Belegen und offenen Prüfungen steht in [docs/abnahme.md](docs/abnahme.md).

## Bauen und prüfen

Swift 6.2+ und das macOS-27-SDK werden benötigt. Xcode oder die passenden Command Line Tools genügen. Es wird kein generiertes Xcode-Projekt benötigt.

```sh
./scripts/test.sh
swift run --build-system native PastaProbe
swift run --build-system native PastaProbe --open
```

`PastaProbe` zeigt ohne `--open` nur Berechtigung und Fokusstatus an. Mit `--open` führt es die echte Tastensequenz aus. Es muss im angemeldeten Desktop laufen und benötigt die entsprechenden Rechte des startenden Terminals. Es liest keine Zwischenablageinhalte.

Unter macOS 27 kann Spotlight durch den Systemprozess `com.apple.campo` in `/System/Applications/Siri AI.app` bereitgestellt werden. Pasta erkennt dort zusätzlich die Kennung `SpotlightSearchField`, um Spotlight von anderen Siri-Oberflächen zu unterscheiden. Bei deaktivierter Campo-Systemfunktion wird der klassische Spotlight-Systemprozess erkannt. Diese Betriebssystemdetails müssen bei späteren macOS-Versionen erneut geprüft werden.

Grundlage: [Apple: Zwischenablagehistorie in Spotlight durchsuchen](https://support.apple.com/en-za/guide/mac-help/mchl40d5b86b/mac).
