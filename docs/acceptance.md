<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Pasta acceptance

## October 23, 2026 — bounded code audit

See the [complete code audit and correction evidence](audit-2026-10-23.md). Current source, build, isolated tooling and core-test evidence supersedes historical automated results only within those categories. No new real-keyboard, UI, quarantined-installation or real-login acceptance is claimed. The approved Markdown GPL is synchronized into the app bundle.

## GitHub preparation — current evidence

The app and test source was verified locally on October 22, 2026 with macOS 27.0.1, Apple Silicon and Xcode 27.1. Later documentation/workflow-only edits do not replace these native results. Pasta 0.1.0 has been prepared as a draft from commit d119a3a; no public release has been published.

| Criterion | Status | Evidence / next step |
| --- | --- | --- |
| English documentation and GPL-3.0-or-later coverage | passed | Project checker passes for all tracked files; both bundled notices match the root copies and GPL bytes match the original GNU text. Relative Markdown links resolve. |
| Public bundle identifiers and shared scheme | passed | Clean clone builds the app and both test targets. Extracted arm64 Release bundle reports eu.mpwg.Pasta, version 0.1.0 and minimum macOS 27.0; all test targets use eu.mpwg. |
| Current core and native localization tests | passed | Xcode MCP RunAllTests at 14:34 CEST: 17 passed, 0 failed/skipped, including English, German and French-to-English fallback. Fresh-clone core test execution also passed. |
| Release app, signature, notices, source and checksums | passed | Downloaded the actual GitHub draft assets for d119a3a: arm64 ZIP signature remains valid after extraction, bundled notices are identical, both SHA-256 checksums match, and source is byte-identical to that commit with resolved dependency source included. |
| Failure paths in project/release checks | passed | Rejected invalid version, dirty checkout, mismatched app version, missing SPDX and malformed JSON. |
| GitHub CI | passed for the release source | [CI run 39781353813](https://github.com/mpwg/pasta/actions/runs/39781353813) passed for d119a3a using the readable v7 action tags. Documentation-only follow-ups do not change the verified app or tooling. |
| Draft release creation on GitHub | passed | [Prepare release run 39781380457](https://github.com/mpwg/pasta/actions/runs/39781380457) passed. [Pasta 0.1.0 draft](https://github.com/mpwg/pasta/releases/tag/untagged-733ad977c07ac7c7dc15) targets d119a3a and contains the app ZIP, corresponding source archive and SHA256SUMS. API confirms isDraft=true and no publication date. |
| Renovate configuration and dependency coverage | passed locally | Renovate 44.176.2 strict validation passed. Its actual managers extracted all three Actions, Python, the Xcode requirement and resolved commit. Replacement simulation updated both the project version and lockfile version/commit together. Maintainer confirmed hosted App access. |
| First hosted Renovate run | not verified | Maintainer confirmed App access; no hosted Dashboard or bot PR was visible at handoff. Configuration validation and local extraction/replacement tests do not establish a hosted run. |
| Source and history publication review | passed within stated limits | Pattern scan of the original 12 commits and first preparation commits found no credential-pattern matches or tracked build artifacts. Old temporary result paths occur in historical docs/abnahme.md only; current documentation removes them. This is a bounded readiness check, not an exhaustive security audit. |
| Quarantined browser download installation and real Accessibility action | not verified | Download the actual release ZIP through a browser and test Gatekeeper approval and the shortcut from /Applications after granting Accessibility. Local extraction and UI tests do not establish this. |
| Launch at login after a real sign-out/sign-in | not verified | Enable launch at login in the installed public build, sign out and back in, and check the menu bar and shortcut. Do not terminate the user's session automatically. |

The implementation is not fully accepted while the manual installation, real-login and first hosted Renovate-run checks remain unverified. Historical results below predate the public identity and are retained only with their original limits.

## Historical localization acceptance

October 22, 2026, 14:02 CEST: Xcode MCP `RunAllTests`, Pasta scheme and test plan, My Mac destination: **17 passed, 0 failed, 0 skipped**. App and test targets built successfully. The result was a local temporary xcresult named `Test-Pasta-2026.10.22_14-02-07-+0200.xcresult`; it is not a published or durable CI artifact.

| Criterion | Historical result | Evidence |
| --- | --- | --- |
| English source and fallback language | passed | Project development region, package default localization and both catalogs use `en`; native UI test with French verifies English fallback. |
| German app translation | passed | All 26 catalog entries translated; UI test checks title, Reset, tagline, permission status, readiness and launch-at-login label in German. |
| English interface | passed | Equivalent UI test checks English labels and the menu bar Settings item. |
| Core error localization independent of app catalog | passed | Separate resource catalog with four messages loaded from the package bundle; four parameterized cases check full German/English text and LocalizedError integration. |
| Dynamic status and error localization | passed | LocalizedStringResource status selection; localized shortcut validation and interpolated login error; catalog checks confirm translations and matching placeholders. |
| Previous core behavior preserved | passed | All ten earlier core cases still pass. |

UI tests open Settings through the menu bar if the window does not appear automatically. The outstanding real-login check below remained outside the localization package.

## Historical functional acceptance

Environment on October 22, 2026: macOS 27.0.1 (26A434), Apple Silicon, Xcode 27.1 (27A9275). The native project was created through Xcode MCP for macOS only. Two package references were added directly with user authorization because the MCP server did not offer the operation. App/UI test build and full test run succeeded: **11 passed, 0 failed, 0 skipped**, app/test source commit `6aa583a`.

Xcode MCP `RunAllTests`, Pasta scheme and test plan, My Mac, 13:18 CEST: nine Swift Testing tests with ten cases and one native XCTest UI test. Historical local evidence: `.build/verification/xcode-tests-native.json`; temporary result name `Test-Pasta-2026.10.22_13-18-21-+0200.xcresult`. These ignored local artifacts are not included in the repository.

| Criterion | Historical result | Evidence |
| --- | --- | --- |
| Hold Command → Space → 4 → release Command | passed | Final Xcode bundle opened history through the global shortcut; focused identifier SpotlightSearchField and static clipboard placeholder observed without reading clipboard contents. Core test checks event order. |
| Skip Space when Spotlight is already focused | passed | Repeated action leaves history focused (`final-e2e-realistic-default.txt`); parameterized core test checks omission of Space. |
| Never send 4 without confirmed focus; one-second timeout | passed | Initial real attempt stopped with a focus error; deterministic core test confirms exact timeout. |
| Missing permission prevents input | passed | Core cases cover missing and revoked permissions while waiting; app integration checks real process permission. |
| Command released after errors | passed | Focus-timeout and event-creation-failure core cases. |
| Overlapping requests ignored | passed | Suspended-first-request test confirms `ignoredWhileRunning` and one sequence. Five real rapid shortcuts leave history open. |
| Open from different apps | passed | After renewed permission and normal restart, final bundle showed allowed/ready status. Three Finder-focused actions and a combined Finder/Codex run opened history without error. Local records: `final-pasta-finder-three-valid.txt`, `final-e2e-realistic-default.txt`. |
| Configurable global shortcut survives restart | passed | Recorded ⌃⌥⌘P in the native recorder, restarted the app (PID 40013 → 40421), observed the same shortcut, and opened history from Codex. Restored ⌘⇧V and repeated three Finder actions. Records: `final-recorder-recorded.txt`, `final-recorder-after-restart.txt`, `final-restored-default-finder.txt`. |
| Explain missing/revoked permissions | passed within stated limits | Final bundle showed missing permission, disabled Open button and explanatory error. Core revocation case passed; manual revocation was not automated. |
| Launch at login after actual sign-in | not verified | Real checkbox registration was enabled and disabled without error (`final-login-registration-on.txt`, `final-login-registration-off.txt`). No actual sign-out occurred. |
| SwiftUI interface and lifecycle, no Catalyst/UIKit | passed | MenuBarExtra and Window entry point; no NSWindow/NSHostingController/AppDelegate construction; Debug build passed. |
| Standard native Xcode project | passed | App, core test and UI targets; macOS-only SDK/platform configuration; no shell build phase; built/tested through MCP. |
| No reading or storing clipboard contents | passed | Process, focus and UI identifier attributes only; no pasteboard API or AX field values. |
| README covers use and limits | passed | Requirements, key sequence, system host detail and test instructions documented. |

This functional package was not fully accepted because real launch at login remained unverified. Install at a stable path, enable launch at login, sign out and back in, and verify the menu bar and shortcut manually.

## Historical final native bundle checks

The unchanged Xcode DerivedData Debug bundle was launched normally as a menu bar app. After manually renewing Accessibility permission and a real app restart, permission was effective. The app had no Dock icon (`activationPolicy=1`). Finder and Codex, already-focused Spotlight and five rapid shortcuts were checked. All detailed evidence was stored locally under `.build/verification/`.

The app was left running with default ⌘⇧V, launch at login disabled, Ready status and no action error (`final-native-state.txt`). Settings was visually inspected with no overlapping or clipped text (`final-native-settings-ready.png`). This is a historical state, not a claim about the currently running app.

Test automation needed complete modifier key-up events and fully closed Spotlight before each starting scenario. Escape first returns clipboard history to Spotlight search; a further Escape closes it. Earlier focus failures with incomplete modifier release are not reliable product failures. The corrected default test and three Finder runs passed. One custom-shortcut Finder run with trailing synthetic modifier releases remains unexplained and is not counted as success; actual recording, restart and opening from Codex establish the custom shortcut behavior. Product code was not changed for these checks.

## Earlier bundle checks before native project migration

An earlier local app bundle showed a menu bar without Dock icon, an explanatory missing-permission error, Ready status after manual approval, recorded ⌃⌥⌘P surviving a real restart (PID 36168 → 36345), and a reset to ⌘⇧V. Finder and five rapid shortcuts showed SpotlightSearchField and the static clipboard placeholder. Opening from Codex was not reliably established at that stage and was rechecked with the final native bundle.

Local historical records: `.build/verification/e2e-custom.txt`, `restarted-shortcut.txt`, `reset-default.txt`, `settings-no-permission.png`, `settings-ready.png`. They do not establish acceptance of a later build.
