# SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
# SPDX-License-Identifier: GPL-3.0-or-later
"""Isolated project checks and packaging fixtures; no release or keyboard actions."""

import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

REPO = Path(__file__).resolve().parents[2]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), REPO / 'scripts' / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


checker = load_script('check-project')
release = load_script('prepare-release')


class RepositoryFixture(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='pasta-tooling-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        for name in ('license.md', 'Pasta/license.md', 'THIRD_PARTY_NOTICES.md',
                     'Pasta/THIRD_PARTY_NOTICES.md', 'Packages/PastaCore/Package.swift'):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / name, target)
        self.git('init', '-q')
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()

    def check(self):
        with patch.object(checker, 'ROOT', self.root):
            return checker.check()


class ProjectChecks(RepositoryFixture):
    def test_valid_repository(self):
        self.assertEqual(self.check(), [])

    def test_strings_in_code_are_not_spdx_declarations(self):
        (self.root / 'example.py').write_text(f'COPYRIGHT = {checker.COPYRIGHT!r}\nLICENSE = {checker.LICENSE!r}\n')
        self.git('add', 'example.py')
        self.assertIn('example.py: missing SPDX copyright or license', self.check())

    def test_sidecar_must_contain_real_declarations(self):
        (self.root / 'image.png').write_bytes(b'fixture')
        sidecar = self.root / 'image.png.license'
        sidecar.write_text(f'{checker.COPYRIGHT}\n{checker.LICENSE}\n')
        self.git('add', '.')
        self.assertEqual(self.check(), [])
        sidecar.write_text('missing attribution\n')
        self.assertIn('image.png: missing SPDX copyright or license', self.check())
        self.assertIn('image.png.license: missing SPDX copyright or license', self.check())

    def test_missing_required_resources_return_errors(self):
        for name in ('license.md', 'Pasta/THIRD_PARTY_NOTICES.md', 'Packages/PastaCore/Package.swift'):
            with self.subTest(name=name):
                path = self.root / name
                data = path.read_bytes()
                path.unlink()
                self.assertTrue(any(f'{name}: cannot read required file:' in error for error in self.check()))
                path.write_bytes(data)

    def test_non_utf8_sidecar_returns_errors(self):
        (self.root / 'image.png').write_bytes(b'fixture')
        (self.root / 'image.png.license').write_bytes(b'\xff')
        self.git('add', '.')
        self.assertTrue(any('cannot read license sidecar' in error for error in self.check()))

    def test_malformed_catalog_and_mismatched_placeholders(self):
        path = self.root / 'Localizable.xcstrings'
        Path(str(path) + '.license').write_text(f'{checker.COPYRIGHT}\n{checker.LICENSE}\n')
        path.write_text('{')
        self.git('add', '.')
        self.assertTrue(any(error.startswith('Localizable.xcstrings:') for error in self.check()))
        catalog = {'sourceLanguage': 'en', 'strings': {'Value %@': {'localizations': {
            language: {'stringUnit': {'state': 'translated', 'value': value}}
            for language, value in [('en', 'Value %@'), ('de', 'Wert %d')]
        }}}}
        path.write_text(json.dumps(catalog))
        self.assertTrue(any('translation placeholders differ' in error for error in self.check()))
        path.write_text('[]')
        self.assertTrue(any(error.startswith('Localizable.xcstrings:') for error in self.check()))


class ReleasePackaging(RepositoryFixture):
    def setUp(self):
        super().setUp()
        self.app = self.root / '.build/release/Build/Products/Release/Pasta.app'
        resources = self.app / 'Contents/Resources'
        resources.mkdir(parents=True)
        for name in ('license.md', 'THIRD_PARTY_NOTICES.md'):
            shutil.copy2(self.root / name, resources / name)
        info = {'CFBundleIdentifier': 'eu.mpwg.Pasta', 'CFBundleShortVersionString': '0.1.0',
                'LSMinimumSystemVersion': '27.0', 'CFBundleExecutable': 'Pasta'}
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
        binary = self.app / 'Contents/MacOS/Pasta'
        binary.parent.mkdir()
        binary.write_bytes(b'fixture, not an executable')
        resolved = self.root / 'Pasta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
        resolved.parent.mkdir(parents=True)
        resolved.write_text('{"pins": []}')
        workspace = self.root / '.build/release/SourcePackages/workspace-state.json'
        workspace.parent.mkdir(parents=True)
        workspace.write_text('{"object": {"dependencies": []}}')
        (self.root / '.gitignore').write_text('.build/\ndist/\n')
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Packaging fixture')
        self.output = self.root / 'dist/0.1.0'

    def prepare(self, version='0.1.0', fail_archive=False, marketing_version='0.1.0'):
        original_run = release.run
        original_subprocess_run = subprocess.run

        def run(*args, cwd=None):
            if args[0] == 'xcodebuild':
                return json.dumps([{'target': 'Pasta', 'buildSettings': {'MARKETING_VERSION': marketing_version}}])
            if args[0] == 'lipo':
                return 'arm64'
            return original_run(*args, cwd=cwd or self.root)

        def native_run(args, **kwargs):
            if args[0] in ('xcodebuild', 'codesign') or args[0] == release.sys.executable:
                return subprocess.CompletedProcess(args, 0, stderr='Signature=adhoc\nTeamIdentifier=not set\n')
            if fail_archive and args[:2] == ['git', 'archive']:
                raise subprocess.CalledProcessError(1, args)
            return original_subprocess_run(args, **kwargs)

        with patch.object(release, 'ROOT', self.root), patch.object(release, 'run', run), \
                patch.object(release.subprocess, 'run', native_run):
            release.prepare(version)

    def test_success_archives_checksums_and_repeat_after_removing_output(self):
        # A stale directory from the old implementation must not block packaging.
        (self.root / '.build/package-0.1.0').mkdir()
        self.prepare()
        with zipfile.ZipFile(self.output / 'Pasta-0.1.0-macOS-arm64.zip') as archive:
            self.assertEqual(archive.read('Pasta-0.1.0-macOS-arm64/Pasta.app/Contents/Resources/license.md'),
                             (self.root / 'license.md').read_bytes())
        with tarfile.open(self.output / 'Pasta-0.1.0-source.tar.gz') as archive:
            self.assertEqual(archive.extractfile('Pasta-0.1.0-source/license.md').read(),
                             (self.root / 'license.md').read_bytes())
        for line in (self.output / 'SHA256SUMS').read_text().splitlines():
            digest, name = line.split('  ')
            self.assertEqual(digest, hashlib.sha256((self.output / name).read_bytes()).hexdigest())
        self.assertEqual(list(self.output.parent.glob('.pasta-*')), [])
        shutil.rmtree(self.output)
        self.prepare()
        self.assertTrue((self.output / 'SHA256SUMS').is_file())

    def test_archive_failure_leaves_no_output_and_retry_succeeds(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.prepare(fail_archive=True)
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.output.parent.glob('.pasta-*')), [])
        self.prepare()
        self.assertTrue((self.output / 'SHA256SUMS').is_file())

    def test_existing_output_is_preserved(self):
        self.output.mkdir(parents=True)
        sentinel = self.output / 'keep.txt'
        sentinel.write_text('existing output')
        with self.assertRaisesRegex(RuntimeError, 'Output already exists'):
            self.prepare()
        self.assertEqual(sentinel.read_text(), 'existing output')

    def dependency(self):
        path = self.root / '.build/release/SourcePackages/checkouts/KeyboardShortcuts'
        path.mkdir(parents=True)
        (path / 'fixture.swift').write_text('// exact dependency fixture\n')
        def git(*args):
            return subprocess.check_output(['git', *args], cwd=path, text=True).strip()
        git('init', '-q')
        git('add', '.')
        git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
            '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Dependency fixture')
        revision = git('rev-parse', 'HEAD')
        resolved = self.root / 'Pasta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
        resolved.write_text(json.dumps({'pins': [{'identity': 'keyboardshortcuts',
            'kind': 'remoteSourceControl', 'state': {'revision': revision}}]}))
        workspace = self.root / '.build/release/SourcePackages/workspace-state.json'
        workspace.write_text(json.dumps({'object': {'dependencies': [{
            'packageRef': {'identity': 'keyboardshortcuts'}, 'subpath': 'KeyboardShortcuts'
        }]}}))
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Pin dependency fixture')
        return path, revision

    def test_dependency_source_and_revision_are_packaged(self):
        path, revision = self.dependency()
        self.prepare()
        with tarfile.open(self.output / 'Pasta-0.1.0-source.tar.gz') as archive:
            self.assertEqual(archive.extractfile('Pasta-0.1.0-source/Vendor/keyboardshortcuts/fixture.swift').read(),
                             (path / 'fixture.swift').read_bytes())
            self.assertIn(revision, archive.extractfile('Pasta-0.1.0-source/BUILD-INFO.txt').read().decode())

    def test_modified_dependency_is_rejected(self):
        path, _ = self.dependency()
        (path / 'fixture.swift').write_text('modified dependency')
        with self.assertRaisesRegex(RuntimeError, 'dependency has local changes'):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_dependency_revision_mismatch_is_rejected(self):
        self.dependency()
        resolved = self.root / 'Pasta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
        pins = json.loads(resolved.read_text())
        pins['pins'][0]['state']['revision'] = '0' * 40
        resolved.write_text(json.dumps(pins))
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Mismatched pin fixture')
        with self.assertRaisesRegex(RuntimeError, 'revision does not match'):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_invalid_version_dirty_checkout_and_version_mismatch(self):
        with self.assertRaisesRegex(RuntimeError, 'Version must be'):
            self.prepare('../escape')
        with self.assertRaisesRegex(RuntimeError, 'differs from'):
            self.prepare(marketing_version='0.2.0')
        (self.root / 'untracked.txt').write_text('dirty fixture')
        with self.assertRaisesRegex(RuntimeError, 'clean committed checkout'):
            self.prepare()
        self.assertFalse(self.output.exists())


if __name__ == '__main__':
    unittest.main()
