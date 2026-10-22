#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
# SPDX-License-Identifier: GPL-3.0-or-later
"""Build and package a clean committed arm64 app and corresponding source."""

from pathlib import Path
import hashlib
import json
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args: str, cwd: Path = ROOT) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def prepare(version: str) -> None:
    require(re.fullmatch(r'\d+\.\d+\.\d+', version) is not None, 'Version must be X.Y.Z without a v prefix.')
    require(not run('git', 'status', '--porcelain'), 'Release requires a clean committed checkout.')
    commit = run('git', 'rev-parse', 'HEAD')
    output = ROOT / 'dist' / version
    require(not output.exists(), f'Output already exists: {output}')
    subprocess.run([sys.executable, 'scripts/check-project.py'], cwd=ROOT, check=True)
    derived = ROOT / '.build' / 'release'
    build_args = [
        'xcodebuild', '-project', 'Pasta.xcodeproj', '-scheme', 'Pasta',
        '-configuration', 'Release', '-destination', 'generic/platform=macOS',
        '-derivedDataPath', str(derived), '-onlyUsePackageVersionsFromResolvedFile',
        'ARCHS=arm64', 'ONLY_ACTIVE_ARCH=NO', 'CODE_SIGN_IDENTITY=-',
        'CODE_SIGN_STYLE=Manual', 'DEVELOPMENT_TEAM=',
    ]
    settings = json.loads(run(*build_args, '-showBuildSettings', '-json'))
    app_settings = next(entry['buildSettings'] for entry in settings if entry['target'] == 'Pasta')
    require(app_settings['MARKETING_VERSION'] == version, 'Requested version differs from the committed app marketing version.')
    subprocess.run([*build_args, 'build'], cwd=ROOT, check=True)
    app = derived / 'Build/Products/Release/Pasta.app'
    with (app / 'Contents/Info.plist').open('rb') as stream:
        info = plistlib.load(stream)
    require(info['CFBundleIdentifier'] == 'eu.mpwg.Pasta', 'Unexpected bundle identifier.')
    require(info['CFBundleShortVersionString'] == version, 'Built app version mismatch.')
    require(info['LSMinimumSystemVersion'] == '27.0', 'Unexpected minimum macOS version.')
    binary = app / 'Contents/MacOS' / info['CFBundleExecutable']
    require(run('lipo', '-archs', str(binary)) == 'arm64', 'Expected an arm64-only binary.')
    subprocess.run(['codesign', '--verify', '--deep', '--strict', '--verbose=2', str(app)], check=True)
    signature = subprocess.run(['codesign', '-dvv', str(app)], text=True, capture_output=True, check=True).stderr
    require('Signature=adhoc' in signature and 'TeamIdentifier=not set' in signature, 'Expected ad hoc signing without a development team.')
    for name in ('license.md', 'THIRD_PARTY_NOTICES.md'):
        bundled = app / 'Contents/Resources' / name
        require(bundled.is_file() and bundled.read_bytes() == (ROOT / name).read_bytes(), f'Missing or mismatched bundled {name}.')
    require(not run('git', 'status', '--porcelain'), 'Build changed the checkout; commit changes before packaging.')
    pins = json.loads((ROOT / 'Pasta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved').read_text())['pins']
    workspace = json.loads((derived / 'SourcePackages/workspace-state.json').read_text())
    checkouts = {entry['packageRef']['identity']: entry for entry in workspace['object']['dependencies']}
    dependencies = []
    for pin in pins:
        require(pin['kind'] == 'remoteSourceControl', f"Source packaging is not implemented for {pin['kind']} pins.")
        entry = checkouts[pin['identity']]
        dependency = derived / 'SourcePackages/checkouts' / entry['subpath']
        revision = pin['state']['revision']
        require(run('git', 'rev-parse', 'HEAD', cwd=dependency) == revision, 'Dependency revision does not match Package.resolved.')
        require(not run('git', 'status', '--porcelain', cwd=dependency), 'Resolved dependency has local changes.')
        dependencies.append((pin['identity'], dependency, revision))
    output.mkdir(parents=True)
    stage = ROOT / '.build' / f'package-{version}'
    require(not stage.exists(), f'Packaging staging directory already exists: {stage}')
    stage.mkdir()
    binary_stage = stage / f'Pasta-{version}-macOS-arm64'
    binary_stage.mkdir()
    subprocess.run(['ditto', str(app), str(binary_stage / 'Pasta.app')], check=True)
    for name in ('license.md', 'THIRD_PARTY_NOTICES.md'):
        shutil.copy2(ROOT / name, binary_stage / name)
    build_info = f'Pasta {version}\nCommit: {commit}\nArchitecture: arm64\nMinimum macOS: 27.0\nSigning: ad hoc; no Developer ID; not notarized\n'
    build_info += ''.join(f'{identity}: {revision}\n' for identity, _, revision in dependencies)
    (binary_stage / 'BUILD-INFO.txt').write_text(build_info)
    (binary_stage / 'INSTALL.txt').write_text(
        'Move Pasta.app to /Applications before starting it and granting Accessibility permission.\n'
        'This app is ad hoc signed, has no Developer ID signature and is not notarized.\n'
        'If macOS blocks it, see System Settings > Privacy & Security > Open Anyway, if offered.\n'
        'Only approve a download you trust. See https://support.apple.com/en-us/102445 .\n'
        'Updates may require renewing permissions and login registration.\n'
        'Bundle identity eu.mpwg.Pasta does not migrate settings from local.pasta.Pasta.\n'
        'No automatic updater is included. See the README in the matching source archive.\n')
    zip_path = output / f'{binary_stage.name}.zip'
    subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(binary_stage), str(zip_path)], check=True)
    source_stage = stage / f'Pasta-{version}-source'
    source_stage.mkdir()
    # git archive contains tracked files only, including the license and build instructions.
    own_tar = stage / 'project.tar'
    subprocess.run(['git', 'archive', '--format=tar', f'--output={own_tar}', commit], cwd=ROOT, check=True)
    with tarfile.open(own_tar) as archive:
        archive.extractall(source_stage, filter='data')
    for identity, dependency, revision in dependencies:
        vendor = source_stage / 'Vendor' / identity
        vendor.mkdir(parents=True)
        vendor_tar = stage / f'{identity}.tar'
        subprocess.run(['git', 'archive', '--format=tar', f'--output={vendor_tar}', revision], cwd=dependency, check=True)
        with tarfile.open(vendor_tar) as archive:
            archive.extractall(vendor, filter='data')
    (source_stage / 'BUILD-INFO.txt').write_text(build_info)
    (source_stage / 'BUILDING-SOURCE.md').write_text(
        '# Building the corresponding source\n\n'
        'This archive contains the exact project commit and resolved KeyboardShortcuts source recorded in BUILD-INFO.txt.\n'
        'Use macOS 27+ and Xcode 27+. No paid Apple account is needed.\n\n'
        'For an online build, open Pasta.xcodeproj and build the shared Pasta scheme as documented in README.md.\n'
        'For an offline build, use Xcode Project > Package Dependencies to remove the remote KeyboardShortcuts reference,\n'
        'then File > Add Package Dependencies > Add Local and choose Vendor/keyboardshortcuts.\n'
        'Link its KeyboardShortcuts product to the Pasta app target if prompted.\n'
        'Keep the existing local Packages/PastaCore reference. Build the Pasta scheme for My Mac using ad hoc signing.\n'
        'All resolved source-control dependencies are included unchanged under Vendor/<package-identity>, with their licenses.\n'
        'See CONTRIBUTING.md for tests and docs/releasing.md for packaging.\n')
    source_path = output / f'{source_stage.name}.tar.gz'
    with tarfile.open(source_path, 'w:gz') as archive:
        archive.add(source_stage, arcname=source_stage.name)
    checksums = ''.join(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n' for path in (zip_path, source_path))
    (output / 'SHA256SUMS').write_text(checksums)
    (output / 'release-notes.md').write_text(
        f'Pasta {version} for Apple Silicon, macOS 27 or later.\n\nSource commit: `{commit}`.\n\n'
        'The app is ad hoc signed, has no Developer ID signature and is **not notarized**. '
        'No automatic updater is included. Extract the ZIP and move Pasta.app to /Applications before starting it. '
        'If blocked, use System Settings → Privacy & Security → Open Anyway, if offered and you trust this download. '
        'Grant Accessibility permission separately. See [installation instructions](https://github.com/mpwg/pasta/blob/' + commit + '/README.md#install).\n\n'
        'The eu.mpwg.Pasta bundle identity does not migrate settings or permissions from older local builds. '
        'Updates may require renewing permissions and launch-at-login registration.\n\n'
        '**Manual acceptance still required:** quarantined browser-download installation, real Accessibility '
        'keyboard action on the distributed build, and launch at login after a real sign-out/sign-in. '
        'Automated checks do not establish these behaviors.\n\n'
        'The corresponding source archive includes the pinned KeyboardShortcuts dependency. '
        'Verify the ZIP and source archive with SHA256SUMS. Pasta is GPL-3.0-or-later; KeyboardShortcuts retains MIT licensing.\n')
    print(f'Prepared {output} from {commit}; no release has been published.')


if __name__ == '__main__':
    try:
        require(sys.version_info >= (3, 12), 'Release packaging requires Python 3.12 or later.')
        require(len(sys.argv) == 2, 'Usage: python3 scripts/prepare-release.py X.Y.Z')
        prepare(sys.argv[1])
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Release preparation failed: {error}', file=sys.stderr)
        sys.exit(1)
