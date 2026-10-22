<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Contributing to Pasta

Use English for documentation, code, comments, issue reports, and pull requests. Keep German strings inside localization catalogs and localization test fixtures. Contributions are provided under GPL-3.0-or-later; preserve existing third-party licenses.

Use a focused branch and pull request. Explain the change, user impact, and current validation. Keep the keyboard core independent of the interface, preserve Swift strict concurrency, and avoid unrelated changes.

## Checks

Use Xcode 27 or later on macOS 27 or later. Open the shared Pasta scheme and run all tests with ⌘U. Run `python3 scripts/check-project.py` for licensing, resource consistency, localization, and file-format checks. CI builds all test targets and runs the core tests. Native UI tests and real keyboard automation require a local interactive Mac session.

Test English, German, and an unsupported language falling back to English when changing visible text. Add localized messages to the correct app or core package catalog. Do not send real keyboard events from unit tests or capture clipboard contents in reports.

## Licensing and resources

Add SPDX copyright and GPL-3.0-or-later headers to new original files. Use a matching `.license` sidecar when the format does not support comments. Keep the Swift tools version and XML/Xcode format declarations first. Do not edit the GPL license text. Keep the root and bundled license and third-party notice files identical.

## Reporting

Use the issue templates for bugs or feature requests. Include macOS/Pasta versions, architecture, installation method, and relevant permission status. Remove personal information, clipboard contents, and credentials from attachments. Report suspected vulnerabilities using the private route in [SECURITY.md](SECURITY.md).
