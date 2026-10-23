#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Matthias Wallner-Géhri
# SPDX-License-Identifier: GPL-3.0-or-later
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


def has_declaration(header: str, declaration: str) -> bool:
    return any(re.fullmatch(r'(?:#|//|/\*|\*)?\s*' + re.escape(declaration) + r'\s*(?:\*/)?', line.strip())
               for line in header.splitlines())


def check() -> list[str]:
    errors = []

    def required_bytes(name: str) -> bytes | None:
        try:
            return (ROOT / name).read_bytes()
        except OSError as error:
            errors.append(f'{name}: cannot read required file: {error.strerror}')
            return None

    paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    for name in filter(None, paths):
        path = ROOT / name
        if not path.exists():
            errors.append(f'{name}: tracked file missing')
            continue
        if name in {'license.md', 'Pasta/license.md'}:
            continue
        try:
            content = path.read_text()
        except UnicodeDecodeError:
            content = ''
        except OSError as error:
            errors.append(f'{name}: cannot read tracked file: {error.strerror}')
            continue
        header = content[:1200]
        sidecar = Path(str(path) + '.license')
        if sidecar.exists():
            try:
                header = sidecar.read_text()
            except (OSError, UnicodeDecodeError) as error:
                errors.append(f'{name}: cannot read license sidecar: {error}')
                header = ''
        if not has_declaration(header, COPYRIGHT) or not has_declaration(header, LICENSE):
            errors.append(f'{name}: missing SPDX copyright or license')
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
        except (ValueError, ET.ParseError, KeyError, TypeError, AttributeError) as error:
            errors.append(f'{name}: {error}')
    for name in ('license.md', 'THIRD_PARTY_NOTICES.md'):
        original = required_bytes(name)
        bundled = required_bytes(f'Pasta/{name}')
        if original is not None and bundled is not None and original != bundled:
            errors.append(f'{name}: root and bundled copies differ')
    license_text = required_bytes('license.md')
    if license_text is not None and hashlib.sha256(license_text).hexdigest() != 'cc5470feed66192387f06ae93aed0bd4fefae5a5fd7c1e54a4acf4ea64f1028b':
        errors.append('GPL license text differs from the approved Markdown text')
    package = required_bytes('Packages/PastaCore/Package.swift')
    if package is not None and not package.startswith(b'// swift-tools-version:'):
        errors.append('Swift tools version must be first')
    return errors


if __name__ == '__main__':
    issues = check()
    for issue in issues:
        print(issue, file=sys.stderr)
    if issues:
        sys.exit(1)
    print('Project checks passed: SPDX coverage, resource formats, localization and bundled notices.')
