# Abnahme Pasta

Stand: 22. Oktober 2026. Umgebung: macOS 27.0.1 (26A434), Apple Silicon, Xcode 27.1 (27A9275). Das native Projekt `Pasta.xcodeproj` wurde über Xcode-MCP erzeugt und auf ausschließlich macOS konfiguriert. Die zwei Paketverknüpfungen wurden mit ausdrücklicher Nutzerfreigabe direkt ergänzt, da der MCP-Server dafür keinen Aufruf bietet. App-/UI-Test-Build und vollständige Testausführung über MCP erfolgreich: **11 Fälle bestanden, 0 fehlgeschlagen, 0 übersprungen**. Geprüfter App-/Test-Quellstand: `6aa583a`.

Xcode-MCP `RunAllTests`, Scheme „Pasta“, Plan „Pasta“, Ziel „My Mac“, 22. Oktober 2026 um 13:18 Uhr: neun Swift-Testing-Tests mit zehn Fällen und ein nativer XCTest-Oberflächentest. Lokaler Ergebnisverweis: `.build/verification/xcode-tests-native.json`; xcresult: `/var/folders/b5/h7f8ws9x5cj4_5n6rtgypdhh0000gn/T/ActionArtifacts/default/RunAllTests/Test-Pasta-2026.10.22_13-18-21-+0200.xcresult`.

| Kriterium | Status | Beleg |
| --- | --- | --- |
| Zusammenhängende Sequenz ⌘ halten → Leertaste → 4 → ⌘ lösen | erfüllt | `PastaProbe --open`: `sent`; AX-Suchfeldkennung `SpotlightSearchField`, Platzhalter danach `Zwischenablage`; keine Feldwerte gelesen. |
| Bei bereits fokussiertem Spotlight keine Leertaste senden | erfüllt | Erster erfolgreicher Systemtest startete mit `Spotlight-Fokus: true`; parametrisierter Kerntest für beide Spotlight-Zustände. |
| Kein ⌘4 bei fehlendem Fokus; Zeitlimit eine Sekunde | erfüllt | Erster echter Probelauf brach mit Fokusfehler ab; deterministischer Kerntest für Fokus-Timeout nach exakt einer Sekunde. |
| Fehlende Berechtigung verhindert Eingaben | erfüllt | Kerntests für fehlende und während der Fokuswartezeit entzogene Rechte; reale Prozessrechte werden zusätzlich in der App-Integration geprüft. |
| ⌘ wird nach Fehlern gelöst | erfüllt | Kerntests für Fokus-Timeout und Fehler bei Ereigniserstellung. |
| Wiederholte Aufrufe während der Sequenz ignorieren | erfüllt | Kerntest suspendiert den ersten Aufruf, prüft den zweiten auf `ignoredWhileRunning` und belegt genau eine ausgeführte Sequenz. Reale Shortcut-Wiederholungen werden zusätzlich geprüft. |
| Öffnen aus verschiedenen Apps | offen | Der endgültige Xcode-Build meldet noch fehlende Bedienungshilfen-Rechte. Auch beim normalen Start ohne Xcode sind AX-Vertrauen und Core-Graphics-Ereignisfreigabe nicht vorhanden; manuelle Erneuerung des Pasta-Eintrags ist angefordert. |
| Frei wählbarer globaler Shortcut und Speicherung nach Neustart | offen | SwiftUI-Aufnahmefeld mit KeyboardShortcuts 3.1.0 implementiert und kompiliert; Integrationstest folgt. |
| Fehlende/entzogene Berechtigung verständlich anzeigen | erfüllt | Am endgültigen Xcode-Bundle sind „Berechtigung fehlt“, deaktivierter Öffnen-Knopf und nach ⌘⇧V der verständliche Fehler nachgewiesen. Kerntest für während der Wartezeit entzogene Rechte bestanden; ein manueller Rechteentzug wurde nicht automatisiert. |
| Autostart nach erneuter Anmeldung | offen | SMAppService.mainApp und SwiftUI-Schalter implementiert; echte Neuanmeldung erforderlich. |
| SwiftUI-Oberfläche und -Lebenszyklus, kein Catalyst/UIKit | erfüllt | `MenuBarExtra` und `Window` im SwiftUI-App-Einstieg; keine NSWindow-/NSHostingController-/AppDelegate-Konstruktion. Debug-Build erfolgreich. |
| Reguläres Xcode-Projekt ohne manuelle Build-Skripte | erfüllt | App-, Swift-Testing- und XCTest-UI-Targets im nativen Projekt. `SDKROOT` und `SUPPORTED_PLATFORMS` ausschließlich `macosx`; keine Shell-Build-Phase. Bauen/Testen über Xcode-MCP. |
| Keine Zwischenablageinhalte lesen oder speichern | erfüllt | Kern verwendet ausschließlich Prozess-, Fokus- und UI-Kennungsattribute, keine Pasteboard-API und keine AX-Feldwerte. |
| README dokumentiert Nutzung und Grenzen | erfüllt | README enthält Voraussetzungen, Tastensequenz, Systemprozess-Besonderheit und Testaufrufe. |

Das Arbeitspaket ist noch nicht vollständig abgenommen.

## Zwischenstand vor der Xcode-Projektumstellung

Am vorherigen lokalen App-Bundle wurden nativ überprüft: Menüleiste ohne Dock-Symbol (`activationPolicy=1`), verständlicher Fehler bei fehlenden Rechten, nach manueller Freigabe Status „Bereit“, echte Shortcut-Aufnahme auf ⌃⌥⌘P und Erhalt nach regulärem App-Neustart (PID 36168 → 36345), anschließend Rücksetzen auf ⌘⇧V. Spotlight wurde aus Finder und nach fünf Auslösungen als Suchfeld `SpotlightSearchField` mit statischem Platzhalter „Zwischenablage“ erkannt. Das Öffnen aus Codex war in diesem Zwischenlauf noch nicht zuverlässig belegt und wird am endgültigen Xcode-Build erneut geprüft.

Historische lokale Belege: `.build/verification/e2e-custom.txt`, `restarted-shortcut.txt`, `reset-default.txt`, `settings-no-permission.png`, `settings-ready.png`. Sie ersetzen keine Prüfung des endgültigen Xcode-Builds.
