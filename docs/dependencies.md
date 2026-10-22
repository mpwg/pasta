<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Dependency maintenance

The hosted Renovate GitHub App has repository access confirmed by the maintainer. `renovate.json` uses the recommended preset and enables a Dependency Dashboard. Updates require review; automerge is disabled. Branches use `codex/renovate/`, with at most three open PRs and two new PRs per hour.

## Coverage

- The built-in GitHub Actions manager updates readable major-version action tags. Digest pinning is explicitly disabled to preserve this project's preference.
- The built-in Swift manager covers remote dependencies in any `Package.swift`. PastaCore currently has no external dependencies.
- Custom regex managers cover exact-version GitHub package requirements in `.xcodeproj/project.pbxproj` and GitHub version/revision pins in `Package.resolved`, including transitive resolved pins. Swift changes are grouped so project requirements and lockfile revisions are updated together.
- KeyboardShortcuts is currently the only external runtime dependency. Its MIT notice is retained in the root and signed app bundle. Python scripts use only the standard library; the workflow's Python runtime selection is managed by the GitHub Actions manager.

Xcode's internal `originHash` is preserved. With `-onlyUsePackageVersionsFromResolvedFile`, the current Xcode toolchain accepts pinned dependencies without rewriting this advisory hash; project and lockfile changes still have to pass CI. New package source formats or non-GitHub URLs require extending the custom managers and their extraction checks.

## Review an update

Inspect release notes and license changes. Confirm that project requirements and resolved version/commit pairs agree, run CI and native localization tests where relevant, and update third-party notices if the dependency's license changes. A resolver or compatibility failure must be fixed before merging; never remove the committed lockfile to bypass it.

The Renovate App performs discovery and PR creation. A configuration file alone does not prove a successful hosted run; check the Dependency Dashboard and bot PRs after the configuration reaches the default branch.
