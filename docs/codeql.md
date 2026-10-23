<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# CodeQL coverage

The versioned [CodeQL workflow](../.github/workflows/codeql.yml) scans Python scripts and GitHub Actions on pull requests to `main`, pushes to `main`, and weekly on Mondays at 05:23 UTC. It can also be started manually. Results appear under GitHub's **Security → Code scanning**. CodeQL performs static security analysis; the separate CI workflow builds the app and runs core tests.

## Swift is currently blocked

Swift source is **not covered by CodeQL**. Pasta requires Xcode 27 and macOS 27. [CodeQL 2.27.3's release notes](https://codeql.github.com/docs/codeql-overview/codeql-changelog/codeql-cli-2.27.3/) state that traced builds (`autobuild` and `manual`) are unsupported on macOS 27, and on macOS 26 with Xcode 27. Swift requires one of those build modes; `build-mode: none` does not support Swift. See [system requirements](https://codeql.github.com/docs/codeql-overview/system-requirements/) and [Swift build options](https://docs.github.com/en/code-security/reference/code-scanning/codeql/build-options-for-compiled-languages).

The initial [default-setup run](https://github.com/mpwg/pasta/actions/runs/39823049694) failed in the Swift `Autobuild` step: `preload_tracer` exited with status 139 before compilation. Python and Actions succeeded. GitHub then removed Swift from default setup, so the overall setup run's successful conclusion does not establish Swift coverage.

Switching to a manual `xcodebuild` command cannot resolve the documented tracing incompatibility. Do not lower Pasta's deployment target, downgrade its SDK, ignore extraction failures, or treat the core test suite as a Swift security scan. Add Swift only when CodeQL officially supports the required toolchain and a GitHub run successfully extracts and analyzes the actual app and core package.

## Repository setup

This workflow uses advanced setup. GitHub's default setup must be disabled before workflow results can be uploaded; see [switching to advanced setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configuring-advanced-setup-for-code-scanning). Keep the workflow on the default branch so its weekly schedule and manual trigger are available.
