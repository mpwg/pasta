#!/usr/bin/env python3
"""Check tracked file licensing, structured resources, and release invariants."""

from pathlib import Path
import json
import hashlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
COPYRIGHT = 'SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri'
LICENSE = 'SPDX-License-Identifier: GPL-3.0-or-later'


def check() -> list[str]:
    errors = []
    paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    for name in filter(None, paths):
        path = ROOT / name
        if not path.exists():
            errors.append(f'{name}: tracked file missing')
            continue
        if name in {'license.md', 'Pasta/license.md'} or name.endswith('.license'):
            continue
        try:
            content = path.read_text()
        except UnicodeDecodeError:
            content = ''
        header = content[:1200]
        sidecar = Path(str(path) + '.license')
        if sidecar.exists():
            header = sidecar.read_text()
        if COPYRIGHT not in header or LICENSE not in header:
            errors.append(f'{name}: missing SPDX copyright or license')
        if path.suffix == '.license':
            continue
        try:
            if path.suffix in {'.json', '.xcstrings'} or path.name == 'Package.resolved':
                data = json.loads(content)
                if path.suffix == '.xcstrings':
                    if data['sourceLanguage'] != 'en':
                        errors.append(f'{name}: source language must be English')
                    for key, value in data['strings'].items():
                        if value.get('extractionState') == 'stale':
                            continue
                        for language in ('en', 'de'):
                            unit = value.get('localizations', {}).get(language, {}).get('stringUnit', {})
                            if not unit.get('value') or unit.get('state') != 'translated':
                                errors.append(f'{name}: missing {language} translation for {key!r}')
                        values = value.get('localizations', {})
                        def placeholders(language):
                            return sorted(re.findall(r'%(?:\d+\$)?(?:@|lld|ld|d|f|s)', values.get(language, {}).get('stringUnit', {}).get('value', '')))
                        if placeholders('en') != placeholders('de'):
                            errors.append(f'{name}: translation placeholders differ for {key!r}')
            if path.suffix in {'.xcscheme', '.xcworkspacedata'}:
                ET.fromstring(content)
        except (ValueError, ET.ParseError, KeyError) as error:
            errors.append(f'{name}: {error}')
    for name in ('license.md', 'THIRD_PARTY_NOTICES.md'):
        if (ROOT / name).read_bytes() != (ROOT / 'Pasta' / name).read_bytes():
            errors.append(f'{name}: root and bundled copies differ')
    license_hash = hashlib.sha256((ROOT / 'license.md').read_bytes()).hexdigest()
    if license_hash != '3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986':
        errors.append('GPL license text differs from the complete original GNU text')
    package = (ROOT / 'Packages/PastaCore/Package.swift').read_text()
    if not package.startswith('// swift-tools-version:'):
        errors.append('Swift tools version must be first')
    return errors


if __name__ == '__main__':
    issues = check()
    for issue in issues:
        print(issue, file=sys.stderr)
    if issues:
        sys.exit(1)
    print('Project checks passed: SPDX coverage, resource formats, localization and bundled notices.')
