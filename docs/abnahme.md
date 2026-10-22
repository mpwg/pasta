# Abnahme Pasta

Stand: 22. Oktober 2026. Umgebung: macOS 27.0.1 (26A434), Apple Silicon, Swift 6.4 über Command Line Tools. Diese Matrix wird nach dem vollständigen App-Build aktualisiert.

| Kriterium | Status | Beleg |
| --- | --- | --- |
| Zusammenhängende Sequenz ⌘ halten → Leertaste → 4 → ⌘ lösen | erfüllt | `PastaProbe --open`: `sent`; AX-Suchfeldkennung `SpotlightSearchField`, Platzhalter danach `Zwischenablage`; keine Feldwerte gelesen. |
| Bei bereits fokussiertem Spotlight keine Leertaste senden | erfüllt | Erster erfolgreicher Systemtest startete mit `Spotlight-Fokus: true`; Kerntest `alreadyOpenDoesNotToggleSpotlight`. |
| Kein ⌘4 bei fehlendem Fokus; Zeitlimit eine Sekunde | erfüllt | Erster echter Probelauf brach mit Fokusfehler ab; deterministischer Kerntest `missingFocusTimesOutAndReleasesCommand`. |
| Fehlende Berechtigung verhindert Eingaben | erfüllt | Kerntest `noPermissionSendsNothing`; reale Berechtigung ist in dieser Umgebung vorhanden. |
| ⌘ wird nach Fehlern gelöst | erfüllt | Kerntests für Fokus-Timeout und Fehler bei Ereigniserstellung. |
| Wiederholte Aufrufe während der Sequenz ignorieren | offen | Zusätzlicher Parallelaufruf-Test folgt. |
| Öffnen aus verschiedenen Apps | offen | App-Integrationstest folgt. |
| Frei wählbarer globaler Shortcut und Speicherung nach Neustart | offen | Menüleiste/Einstellungen noch nicht implementiert. |
| Fehlende/entzogene Berechtigung verständlich anzeigen | offen | Oberfläche noch nicht implementiert. |
| Autostart nach erneuter Anmeldung | offen | Oberfläche noch nicht implementiert; echte Neuanmeldung erforderlich. |
| Keine Zwischenablageinhalte lesen oder speichern | erfüllt | Kern verwendet ausschließlich Prozess-, Fokus- und UI-Kennungsattribute, keine Pasteboard-API und keine AX-Feldwerte. |
| README dokumentiert Nutzung und Grenzen | erfüllt | README enthält Voraussetzungen, Tastensequenz, Systemprozess-Besonderheit und Testaufrufe. |

Das Arbeitspaket ist noch nicht vollständig abgenommen.
