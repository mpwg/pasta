<!--
SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Preparing a release

## GitHub workflow

1. Merge the intended changes into the default branch. Check [acceptance](acceptance.md) and keep unresolved manual checks visible in release notes.
2. Set the app's marketing version in Xcode, update the changelog, commit, and push. The initial version is `0.1.0`.
3. In Actions, run **Prepare release** on the intended branch with that exact version, without `v`. The workflow tests the checked-out commit, then creates an arm64 Release build with ad hoc signing and no development team, Developer ID certificate or notarization.
4. Inspect the **draft** release, its exact source commit, app ZIP, matching source archive, checksums and validation results. The source archive includes the pinned KeyboardShortcuts source and offline build guidance. Do not move a release tag or replace published assets.
5. Download through a browser, install in `/Applications`, verify Gatekeeper approval and Accessibility, and test launch at login after signing out and in. Update acceptance evidence and release notes. Unverified items must remain explicit.
6. Publish the draft manually when you choose to distribute it. Running the workflow never publishes it automatically.

Private vulnerability reporting must be enabled in the repository's Security settings. Repository secret scanning and push protection should remain enabled. Workflows use maintained major-version action tags, read-only default permissions and a separate release job with `contents: write`. Pull request code never receives release permissions.

## Local packaging

On an Apple Silicon Mac with Xcode 27+, run from a clean committed checkout:

```sh
python3 scripts/check-project.py
python3 scripts/prepare-release.py 0.1.0
```

Artifacts go to ignored `dist/0.1.0/`. The script refuses dirty tracked files, untracked non-ignored files, invalid/mismatched versions and an existing output directory. It builds from the current commit and verifies bundle identity, minimum OS, architecture, ad hoc signing and bundled license files. It does not run tests; run the checks documented in CONTRIBUTING.md before packaging locally. The GitHub workflow gates packaging on its CI job.

The source archive contains the complete tracked project at the recorded commit and the resolved dependency's tracked source. `BUILDING-SOURCE.md` explains how to use the included dependency without fetching it. App ZIP and source archive use the same recorded commit. `SHA256SUMS` covers both archives. The app ZIP includes license notices and build information outside the app, as well as notices inside the signed bundle.

## Compatibility

Only Apple Silicon/macOS 27+ downloads are currently prepared. No updater is installed. Ad hoc signatures can change between builds, so permission renewal and login registration may be required after replacement. The `eu.mpwg.Pasta` identity does not migrate preferences or permissions from `local.pasta.Pasta`.

The archive and checksum checks do not establish successful quarantined installation or a real login session. Those require the manual checks above. Retain both source and binary assets for every published version.
