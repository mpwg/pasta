# Abnahme Pasta

## Lokalisierung: Englisch als Ausgangssprache, Deutsch als erste Übersetzung

Aktuelle Prüfung am 22. Oktober 2026 um 14:02 Uhr: Xcode-MCP `RunAllTests`, Scheme und Plan „Pasta“, Ziel „My Mac“: **17 Fälle bestanden, 0 fehlgeschlagen, 0 übersprungen**. Der Build einschließlich der Testtargets war erfolgreich. Ergebnis: `/var/folders/b5/h7f8ws9x5cj4_5n6rtgypdhh0000gn/T/ActionArtifacts/default/RunAllTests/Test-Pasta-2026.10.22_14-02-07-+0200.xcresult`.

| Kriterium | Status | Beleg |
| --- | --- | --- |
| Englisch als Ausgangs- und Rückfallsprache | erfüllt | Projekt-`developmentRegion`, Paket-`defaultLocalization` und beide Kataloge auf `en`; nativer Oberflächentest mit Französisch bestätigt englische Rückfalltexte. |
| Deutsche Übersetzung der App | erfüllt | Alle 26 Katalogeinträge übersetzt; nativer Oberflächentest prüft Fenstertitel, Reset-Knopf, Untertitel, Berechtigungsstatus, Bereitschaft und Autostart-Beschriftung auf Deutsch. |
| Englische Oberfläche | erfüllt | Derselbe native Oberflächentest prüft die englischen Texte; der Aufruf über das Menüleistensymbol prüft zusätzlich den lokalisierten Menüpunkt „Settings …“. |
| PastaCore-Fehler unabhängig vom App-Katalog lokalisiert | erfüllt | Eigener Ressourcenkatalog mit vier Meldungen und explizitem Paket-Bundle; vier parametrisierte Fälle prüfen jeweils den vollständigen deutschen und englischen Text sowie die `LocalizedError`-Anbindung. |
| Dynamische Statusanzeigen und weitere Fehlermeldungen lokalisiert | erfüllt | Statusauswahl verwendet `LocalizedStringResource`; Shortcut-Validierung und interpolierter Autostart-Fehler verwenden `String(localized:)`. Katalogprüfung bestätigt vollständige Texte und identische Platzhalter. |
| Bisheriges Kernverhalten erhalten | erfüllt | Alle zehn bisherigen Kerntestfälle weiterhin erfolgreich. |

Die Oberflächentests öffnen die Einstellungen bei Bedarf über das Menüleistensymbol, da das Fenster beim automatisierten Start nicht zuverlässig erscheint. Der bestehende Autostart-Vorbehalt nach echter Neuanmeldung aus der folgenden ursprünglichen Abnahme bleibt bestehen und betrifft nicht dieses Lokalisierungspaket.

## Ursprüngliche Funktionsabnahme

Stand: 22. Oktober 2026. Umgebung: macOS 27.0.1 (26A434), Apple Silicon, Xcode 27.1 (27A9275). Das native Projekt `Pasta.xcodeproj` wurde über Xcode-MCP erzeugt und auf ausschließlich macOS konfiguriert. Die zwei Paketverknüpfungen wurden mit ausdrücklicher Nutzerfreigabe direkt ergänzt, da der MCP-Server dafür keinen Aufruf bietet. App-/UI-Test-Build und vollständige Testausführung über MCP erfolgreich: **11 Fälle bestanden, 0 fehlgeschlagen, 0 übersprungen**. Geprüfter App-/Test-Quellstand: `6aa583a`.

Xcode-MCP `RunAllTests`, Scheme „Pasta“, Plan „Pasta“, Ziel „My Mac“, 22. Oktober 2026 um 13:18 Uhr: neun Swift-Testing-Tests mit zehn Fällen und ein nativer XCTest-Oberflächentest. Lokaler Ergebnisverweis: `.build/verification/xcode-tests-native.json`; xcresult: `/var/folders/b5/h7f8ws9x5cj4_5n6rtgypdhh0000gn/T/ActionArtifacts/default/RunAllTests/Test-Pasta-2026.10.22_13-18-21-+0200.xcresult`.

| Kriterium | Status | Beleg |
| --- | --- | --- |
| Zusammenhängende Sequenz ⌘ halten → Leertaste → 4 → ⌘ lösen | erfüllt | Endgültiges Xcode-Bundle öffnet über den globalen Shortcut die Historie: AX-Suchfeldkennung `SpotlightSearchField`, statischer Platzhalter danach `Zwischenablage`; keine Zwischenablageinhalte gelesen. Der Kerntest belegt die Ereignisreihenfolge. |
| Bei bereits fokussiertem Spotlight keine Leertaste senden | erfüllt | Endgültiges Xcode-Bundle lässt bei erneuter Shortcut-Auslösung die bereits offene Historie fokussiert (`final-e2e-realistic-default.txt`); parametrisierter Kerntest belegt das Überspringen der Leertaste. |
| Kein ⌘4 bei fehlendem Fokus; Zeitlimit eine Sekunde | erfüllt | Erster echter Probelauf brach mit Fokusfehler ab; deterministischer Kerntest für Fokus-Timeout nach exakt einer Sekunde. |
| Fehlende Berechtigung verhindert Eingaben | erfüllt | Kerntests für fehlende und während der Fokuswartezeit entzogene Rechte; reale Prozessrechte werden zusätzlich in der App-Integration geprüft. |
| ⌘ wird nach Fehlern gelöst | erfüllt | Kerntests für Fokus-Timeout und Fehler bei Ereigniserstellung. |
| Wiederholte Aufrufe während der Sequenz ignorieren | erfüllt | Kerntest suspendiert den ersten Aufruf, prüft den zweiten auf `ignoredWhileRunning` und belegt genau eine ausgeführte Sequenz. Fünf reale globale Auslösungen am endgültigen Bundle lassen die Zwischenablagehistorie geöffnet. |
| Öffnen aus verschiedenen Apps | erfüllt | Nach erneuerter Freigabe und regulärem App-Neustart zeigt der endgültige Xcode-Build „Bedienungshilfen erlaubt“ und „Bereit“. Drei gültige Auslösungen aus bestätigtem Finder-Fokus sowie der gemeinsame Lauf aus Finder und Codex öffneten die Historie: `SpotlightSearchField`, statischer Platzhalter „Zwischenablage“, kein Fehler. Belege: `final-pasta-finder-three-valid.txt`, `final-e2e-realistic-default.txt`. |
| Frei wählbarer globaler Shortcut und Speicherung nach Neustart | erfüllt | Im nativen Aufnahmefeld tatsächlich ⌃⌥⌘P aufgezeichnet. Nach regulärem App-Neustart PID 40013 → 40421 unverändert angezeigt; der geänderte Shortcut öffnete die Historie aus Codex. Anschließend auf ⌘⇧V zurückgesetzt und erneut drei erfolgreiche Finder-Auslösungen geprüft. Belege: `final-recorder-recorded.txt`, `final-recorder-after-restart.txt`, `final-restored-default-finder.txt`. |
| Fehlende/entzogene Berechtigung verständlich anzeigen | erfüllt | Am endgültigen Xcode-Bundle sind „Berechtigung fehlt“, deaktivierter Öffnen-Knopf und nach ⌘⇧V der verständliche Fehler nachgewiesen. Kerntest für während der Wartezeit entzogene Rechte bestanden; ein manueller Rechteentzug wurde nicht automatisiert. |
| Autostart nach erneuter Anmeldung | nicht prüfbar | Registrierung über die echte Checkbox erfolgreich ein- und wieder ausgeschaltet, jeweils ohne Fehlermeldung (`final-login-registration-on.txt`, `final-login-registration-off.txt`). Die laufende Nutzersitzung wurde nicht abgemeldet; eine echte Neuanmeldung bleibt erforderlich. |
| SwiftUI-Oberfläche und -Lebenszyklus, kein Catalyst/UIKit | erfüllt | `MenuBarExtra` und `Window` im SwiftUI-App-Einstieg; keine NSWindow-/NSHostingController-/AppDelegate-Konstruktion. Debug-Build erfolgreich. |
| Reguläres Xcode-Projekt ohne manuelle Build-Skripte | erfüllt | App-, Swift-Testing- und XCTest-UI-Targets im nativen Projekt. `SDKROOT` und `SUPPORTED_PLATFORMS` ausschließlich `macosx`; keine Shell-Build-Phase. Bauen/Testen über Xcode-MCP. |
| Keine Zwischenablageinhalte lesen oder speichern | erfüllt | Kern verwendet ausschließlich Prozess-, Fokus- und UI-Kennungsattribute, keine Pasteboard-API und keine AX-Feldwerte. |
| README dokumentiert Nutzung und Grenzen | erfüllt | README enthält Voraussetzungen, Tastensequenz, Systemprozess-Besonderheit und Testaufrufe. |

Das Arbeitspaket ist wegen der ausstehenden Autostart-Prüfung nach echter Neuanmeldung noch nicht vollständig abgenommen. Nächster manueller Schritt: Pasta an den dauerhaften Installationsort kopieren und dort starten, Autostart aktivieren, regulär ab- und wieder anmelden und anschließend das laufende Menüleistensymbol sowie den Shortcut prüfen.

## Native Prüfung des endgültigen Xcode-Bundles

Geprüft wurde der unveränderte Debug-Build aus Xcodes DerivedData, regulär als Menüleisten-App gestartet. Nach manuell erneuerter Bedienungshilfen-Freigabe und einem echten App-Neustart war die Berechtigung wirksam. Die App lief ohne Dock-Symbol (`activationPolicy=1`). Neben dem Öffnen aus Finder und Codex wurden bereits geöffnetes Spotlight und fünf rasche Auslösungen erfolgreich geprüft. Alle lokalen Belege liegen unter `.build/verification/`.

Hinterlassener Zustand: Pasta läuft regulär mit Standardshortcut ⌘⇧V, Autostart ausgeschaltet, Status „Bereit“, kein Aktionsfehler. Beleg: `final-native-state.txt`. Die eigene Einstellungsoberfläche wurde zusätzlich visuell geprüft: `final-native-settings-ready.png`, keine überlappenden oder abgeschnittenen Texte.

Die Tastaturautomation musste vollständige Modifier-KeyUps senden und Spotlight vor jedem Ausgangstest vollständig schließen: Escape wechselt von der Zwischenablage zunächst in die Spotlight-Hauptsuche, erst ein weiteres Escape schließt das Fenster. Frühere Fokusfehler mit unvollständig freigegebenen synthetischen Sondertasten sind keine belastbaren Produktfehler. Der korrigierte Default-Test und drei separate Finder-Durchläufe waren erfolgreich. Ein Custom-Finder-Lauf mit nachlaufenden synthetischen Modifier-Releases bleibt als ungeklärter Testlauf dokumentiert; er dient nicht als Erfolgsbeleg. Der benutzerdefinierte Shortcut ist durch tatsächliche Aufnahme, echten Neustart und erfolgreiches Öffnen aus Codex belegt. Der Produktcode wurde für diese Prüfungen nicht verändert.

## Zwischenstand vor der Xcode-Projektumstellung

Am vorherigen lokalen App-Bundle wurden nativ überprüft: Menüleiste ohne Dock-Symbol (`activationPolicy=1`), verständlicher Fehler bei fehlenden Rechten, nach manueller Freigabe Status „Bereit“, echte Shortcut-Aufnahme auf ⌃⌥⌘P und Erhalt nach regulärem App-Neustart (PID 36168 → 36345), anschließend Rücksetzen auf ⌘⇧V. Spotlight wurde aus Finder und nach fünf Auslösungen als Suchfeld `SpotlightSearchField` mit statischem Platzhalter „Zwischenablage“ erkannt. Das Öffnen aus Codex war in diesem Zwischenlauf noch nicht zuverlässig belegt und wird am endgültigen Xcode-Build erneut geprüft.

Historische lokale Belege: `.build/verification/e2e-custom.txt`, `restarted-shortcut.txt`, `reset-default.txt`, `settings-no-permission.png`, `settings-ready.png`. Sie ersetzen keine Prüfung des endgültigen Xcode-Builds.
