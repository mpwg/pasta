# Pasta-App-Icon

Gewählt wurde Entwurf A: eine goldene Farfalle als Klemme auf einer cremefarbenen Zwischenablage vor orangefarbenem Hintergrund.

![Pasta-App-Icon](images/pasta-icon.png)

## Bearbeiten und Einbindung

Die editierbare Quelle ist [`Pasta/AppIcon.icon`](../Pasta/AppIcon.icon). Sie lässt sich direkt in Apples Icon Composer öffnen. Der orange Verlauf ist ein nativer Hintergrund; das freigestellte Motiv liegt separat in `Assets/pasta-clip.png` mit 1024 × 1024 Pixeln und echtem Alphakanal. Der graue Präsentationshintergrund aus dem Entwurf ist entfernt. Die äußere Form und die Erscheinungsvarianten rendert Icon Composer. Der Dunkelmodus verwendet den vom System abgeleiteten dunklen Hintergrund.

Xcode erkennt die Datei im synchronisierten App-Ordner automatisch und kompiliert sie mit `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Der vorherige leere `AppIcon.appiconset` wurde entfernt. Die Einstellungen zeigen das tatsächliche App-Icon aus dem laufenden Bundle an.

## Herkunft

Das Motiv wurde mit der integrierten Bildgenerierung erzeugt und nach Auswahl von A mit derselben Bildgenerierung freigestellt. Kein externer Bilddienst oder CLI-Fallback wurde verwendet. Das Paket wurde mithilfe des installierten Skills [compose-app-icon](https://github.com/giginet/apple-icon-composer-skill) erstellt und validiert.

Finaler Bearbeitungsprompt mit Entwurf A als Referenz:

> Use case: background-extraction. Edit target: the attached selected macOS Pasta app icon. Extract ONLY the ivory clipboard, its overlapping ivory paper sheets, and the golden farfalle pasta clip, retaining their exact design, relative positions, proportions, colors and beautiful tactile shading. Remove BOTH the gray outside background AND the entire orange rounded-square background tile completely. Deliver the clipboard-and-farfalle foreground centered on a square fully transparent canvas with comfortable transparent margins around all sides (roughly 15% on left/right and 8% top/bottom). Preserve the object, do not redesign, no extra objects, no text, no gray border, no orange background, no baked-in background shadow or glow. True alpha transparency around the extracted object and soft edge antialiasing. This foreground will be layered over an orange native Icon Composer background.

## Prüfung am 22. Oktober 2026

- Paket und Asset-Verweise mit dem Schema-Validator des Skills geprüft.
- Helle und dunkle macOS-Vorschau mit Apples `ictool` erfolgreich gerendert und visuell geprüft.
- Xcode-Build erfolgreich; Build-Protokoll bestätigt `AppIcon.icon` als Eingabe von `actool` und die Erstellung von `AppIcon.icns` und `Assets.car`.
- `CFBundleIconName = AppIcon` im gebauten App-Bundle bestätigt; das kompilierte `.icns` exportiert und visuell ohne grauen Außenrahmen geprüft.
- Xcode-MCP-Testlauf um 14:11 Uhr: **17 bestanden, 0 fehlgeschlagen, 0 übersprungen**, einschließlich der deutschen und englischen Einstellungsoberfläche sowie des englischen Sprachfallbacks.
