<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Changelog

## Unreleased

- Prepare public GitHub distribution under GPL-3.0-or-later.
- Use the `eu.mpwg` bundle identifier prefix. Earlier local preferences, permissions, and login registrations are not migrated.
- Provide English project documentation while retaining German app localization.
- Add CI and a manually triggered release workflow that prepares an Apple Silicon app, checksums, corresponding source, and a draft release.
- Keep ad hoc signing without Developer ID signing or Apple notarization.

## 0.1.0 — Initial development

- Native SwiftUI menu bar app for macOS 27 and later.
- Configurable global shortcut for opening macOS clipboard history through Spotlight.
- Accessibility permission guidance and optional launch at login.
- English and German localization, English fallback, native app icon, and core/UI tests.

This section describes development history, not a previously published binary release.
