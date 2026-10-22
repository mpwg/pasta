<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Security policy

Security fixes target the current source on the default branch and the latest published release. No response time is guaranteed.

## Report a vulnerability privately

Use [GitHub private vulnerability reporting](https://github.com/mpwg/pasta/security/advisories/new). Do not disclose exploitable details or sensitive clipboard contents in public issues. Include the affected commit or version, macOS version, reproduction steps, and potential impact. The repository must have private vulnerability reporting enabled for this link to accept reports.

## Security boundaries

Pasta must not read or store clipboard contents or send telemetry. It sends the 4 key only to the confirmed system Spotlight process, stops when focus or permissions cannot be confirmed, and releases its synthetic Command key after errors or cancellation.

Release apps are ad hoc signed and not notarized. SHA-256 checksums detect file corruption but do not establish developer identity. Verify that downloads and source come from this repository. Never disable macOS security globally to install Pasta.
