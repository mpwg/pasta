#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ "$developer_dir" == */CommandLineTools ]]; then
    printf '%s\n' 'Für die SwiftUI-App wird Xcode 27 benötigt. Die Command Line Tools enthalten die benötigten SwiftUI-Makros nicht.' >&2
    printf '%s\n' 'Beispiel: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build-app.sh' >&2
    exit 1
fi

swift build -c release --product Pasta
binary_dir="$(swift build -c release --show-bin-path)"
mkdir -p dist
stage_dir="$(mktemp -d "$PWD/dist/.pasta-build.XXXXXX")"
trap 'rm -rf "$stage_dir"' EXIT
app_dir="$stage_dir/Pasta.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp Resources/Info.plist "$app_dir/Contents/Info.plist"
cp "$binary_dir/Pasta" "$app_dir/Contents/MacOS/Pasta"
for resource in "$binary_dir"/*.bundle; do
    [[ -d "$resource" ]] || continue
    cp -R "$resource" "$app_dir/Contents/Resources/"
done
# Local development signature only; no publishing or Developer ID signing.
codesign --force --sign - "$app_dir"
codesign --verify --strict "$app_dir"
rm -rf "$PWD/dist/Pasta.app"
mv "$app_dir" "$PWD/dist/Pasta.app"
printf 'App erstellt: %s\n' "$PWD/dist/Pasta.app"
