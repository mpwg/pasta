#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Command Line Tools include Swift Testing, but SwiftPM does not yet discover
# their framework and macro locations automatically on macOS 27.
developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ "$developer_dir" == */CommandLineTools ]]; then
    framework_dir="$developer_dir/Library/Developer/Frameworks"
    macro_library="$developer_dir/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
    swift test --package-path Packages/PastaCore --build-system native \
        -Xswiftc "-F$framework_dir" \
        -Xswiftc -load-plugin-library -Xswiftc "$macro_library" \
        -Xlinker "-F$framework_dir" \
        -Xlinker -rpath -Xlinker "$framework_dir" "$@"
else
    swift test --package-path Packages/PastaCore "$@"
fi
